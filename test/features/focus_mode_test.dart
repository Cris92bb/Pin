import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/atomic_step/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/focus_mode/ui/focus_mode_view.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/shared/ui/pin_button.dart';
import 'package:pin/shared/ui/pin_tokens.dart';

void main() {
  testWidgets('FocusModeView initializes timer, toggles steps, and completes task',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final task = PinTask(
      id: 'task_deep_work',
      title: 'Deep Architecture Focus',
      description: 'Zero external cloud or API dependencies',
      status: TaskStatus.today,
      energyTag: 'deep-focus',
      estimatedMinutes: 30,
      trackedSeconds: 0,
      subtasks: const [
        AtomicStep(id: 's1', title: 'Subtask 1', isCompleted: false),
        AtomicStep(id: 's2', title: 'Subtask 2', isCompleted: false),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final fakeStorage = MemoryStorageAdapter([task.toJson()]);
    bool hasExited = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: FocusModeView(
            task: task,
            onExit: () => hasExited = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Focus Mode UI
    expect(find.text('SINGLE-TASK IMMERSION'), findsOneWidget);
    expect(find.text('Deep Architecture Focus'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    // Let timer tick 2 seconds
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:02'), findsOneWidget);

    // Pause timer
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Verify both Resume and Reset buttons are identical in size
    final resumeSize =
        tester.getSize(find.widgetWithText(PinButton, 'Resume'));
    final resetSize =
        tester.getSize(find.widgetWithText(PinButton, 'Reset'));
    expect(resumeSize.width, equals(resetSize.width));
    expect(resumeSize.height, equals(resetSize.height));

    // Tap Reset and verify timer resets
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);

    // Toggle subtask checkbox
    final firstCheckbox = find.byType(InkWell).first;
    await tester.tap(firstCheckbox);
    await tester.pump();

    // Click "Done & Exit"
    final doneBtn = find.text('Done & Exit');
    expect(doneBtn, findsOneWidget);
    await tester.tap(doneBtn);
    await tester.pump();

    // Verify celebration view appears
    expect(find.text('Task Completed!'), findsOneWidget);

    // Wait for celebration delay
    await tester.pump(const Duration(seconds: 1));
    expect(hasExited, isTrue);
  });

  testWidgets('FocusModeView renders cleanly with Light Mode theme',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final task = PinTask(
      id: 'task_light_focus',
      title: 'Light Mode Focus Task',
      description: 'Verifying light mode background and text colors',
      status: TaskStatus.today,
      energyTag: 'deep-focus',
      estimatedMinutes: 25,
      trackedSeconds: 60,
      subtasks: const [
        AtomicStep(id: 's1', title: 'Light Subtask 1', isCompleted: false),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final fakeStorage = MemoryStorageAdapter([task.toJson()]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: FocusModeView(
            task: task,
            onExit: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Focus Mode UI in light mode
    expect(find.text('SINGLE-TASK IMMERSION'), findsOneWidget);
    expect(find.text('Light Mode Focus Task'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);

    // Verify scaffold uses lightPhoneFrameBg in light mode
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(PinTokens.lightPhoneFrameBg));

    // Verify Pause and Reset buttons
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    final pauseSize = tester.getSize(find.widgetWithText(PinButton, 'Pause'));
    final resetSize = tester.getSize(find.widgetWithText(PinButton, 'Reset'));
    expect(pauseSize.width, equals(resetSize.width));
    expect(pauseSize.height, equals(resetSize.height));
  });

  testWidgets(
      'FocusModeView displays sticky minimized timer banner when scrolling past hero timer',
      (tester) async {
    tester.view.physicalSize = const Size(500, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final task = PinTask(
      id: 'task_scroll_test',
      title: 'Long Focus Task for Sticky Banner Scroll Verification',
      description: 'Verifying scroll-triggered sticky minimized timer banner',
      status: TaskStatus.today,
      energyTag: 'deep-focus',
      estimatedMinutes: 45,
      trackedSeconds: 120,
      subtasks: List.generate(
        10,
        (i) => AtomicStep(
          id: 'step_$i',
          title: 'Step number $i in focus sequence',
          isCompleted: false,
        ),
      ),
      createdAt: now,
      updatedAt: now,
    );

    final fakeStorage = MemoryStorageAdapter([task.toJson()]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: FocusModeView(
            task: task,
            onExit: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // At top of page, sticky banner should not be present
    expect(find.byKey(const ValueKey('sticky_timer_banner')), findsNothing);

    // Scroll down past 170px threshold
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Sticky banner should now be visible
    expect(find.byKey(const ValueKey('sticky_timer_banner')), findsOneWidget);

    // Test pause interaction on sticky banner
    final stickyPauseBtn = find.descendant(
      of: find.byKey(const ValueKey('sticky_timer_banner')),
      matching: find.text('Pause'),
    );
    expect(stickyPauseBtn, findsOneWidget);
    await tester.tap(stickyPauseBtn);
    await tester.pumpAndSettle();

    final stickyResumeBtn = find.descendant(
      of: find.byKey(const ValueKey('sticky_timer_banner')),
      matching: find.text('Resume'),
    );
    expect(stickyResumeBtn, findsOneWidget);

    // Scroll back to top
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();

    // Sticky banner should hide when scrolled back to top
    expect(find.byKey(const ValueKey('sticky_timer_banner')), findsNothing);
  });

  testWidgets(
      'FocusModeView intercepts system/Android back navigation via PopScope and acts as back button',
      (tester) async {
    final now = DateTime.now();
    final task = PinTask(
      id: 'task_back_test',
      title: 'Back Navigation Test Task',
      description: 'Verifying PopScope Android back gesture interception',
      status: TaskStatus.today,
      energyTag: 'deep-focus',
      estimatedMinutes: 20,
      trackedSeconds: 0,
      createdAt: now,
      updatedAt: now,
    );

    final fakeStorage = MemoryStorageAdapter([task.toJson()]);
    bool hasExited = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: FocusModeView(
            task: task,
            onExit: () => hasExited = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Back Navigation Test Task'), findsOneWidget);
    expect(hasExited, isFalse);

    // Simulate system back navigation (Android back gesture / button)
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    final didHandle = await widgetsAppState.didPopRoute();
    expect(didHandle, isTrue);
    await tester.pumpAndSettle();

    // Verify focus mode exited
    expect(hasExited, isTrue);
  });
}


