import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/focus_mode/ui/focus_mode_view.dart';
import 'package:pin/pages/home/home_page.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/widgets/kanban_board/task_card.dart';

void main() {
  testWidgets('renders HomePage with companion layered deck and default state',
      (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header branding
    expect(find.text('Pin'), findsOneWidget);

    // Verify Stacked Deck tabs
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Backlog'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Verify WIP slots available text
    expect(find.textContaining('slots available'), findsOneWidget);
  });

  testWidgets('displays task cards with estimation and energy tags',
      (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final sampleTasks = [
      PinTask(
        id: 'task_101',
        title: 'Ship Pin MVP',
        description: 'Complete all architectural layers',
        status: TaskStatus.today,
        energyTag: 'deep-focus',
        estimatedMinutes: 45,
        trackedSeconds: 60,
        tags: ['#dev', '#ui'],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final fakeStorage = MemoryStorageAdapter(
      sampleTasks.map((t) => t.toJson()).toList(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify task is rendered
    expect(find.text('Ship Pin MVP'), findsOneWidget);
    expect(find.text('DEEP FOCUS'), findsOneWidget);
    expect(find.text('~45m'), findsOneWidget);
    expect(find.text('#dev'), findsOneWidget);
    expect(find.byType(TaskCard), findsOneWidget);
  });

  testWidgets('clicking card transitions to single-task Focus Mode',
      (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final sampleTasks = [
      PinTask(
        id: 'task_focus',
        title: 'Deep Execution Task',
        status: TaskStatus.today,
        energyTag: 'deep-focus',
        estimatedMinutes: 15,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final fakeStorage = MemoryStorageAdapter(
      sampleTasks.map((t) => t.toJson()).toList(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the task card directly to enter Focus Mode
    final card = find.byType(TaskCard);
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Verify we are in Focus Mode!
    expect(find.byType(FocusModeView), findsOneWidget);
    expect(find.textContaining('FOCUS'), findsOneWidget);
    expect(find.text('Deep Execution Task'), findsOneWidget);
    expect(find.text('Atomic Subtasks'), findsOneWidget);
  });

  testWidgets('smoothly transitions between drawers via tab tap and keyboard shortcuts',
      (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially active drawer is 'To do'
    expect(find.text('No active Pins today.'), findsOneWidget);

    // 1. Tap the Backlog inactive tab
    final backlogTab = find.text('Backlog');
    expect(backlogTab, findsOneWidget);
    await tester.tap(backlogTab);
    await tester.pumpAndSettle();

    // Now active drawer is Backlog
    expect(find.text('Backlog is empty.'), findsOneWidget);

    // 2. Press '3' key to switch to Done drawer
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pumpAndSettle();
    expect(find.text('No completed Pins yet.'), findsOneWidget);

    // 3. Press 'arrowLeft' to navigate back to Today (To do) drawer
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('No active Pins today.'), findsOneWidget);
  });

  testWidgets('options menu displays Exit button', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open options menu
    final optionsButton = find.byIcon(Icons.more_horiz_rounded);
    expect(optionsButton, findsOneWidget);
    await tester.tap(optionsButton);
    await tester.pumpAndSettle();

    // Verify Exit menu item is shown
    expect(find.text('Exit'), findsOneWidget);
  });

  testWidgets('animates tab change with outgoing drawer shrinking/fading back and incoming tab fading in',
      (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeStorage = MemoryStorageAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) => TaskStateNotifier(
              storage: fakeStorage,
              seedInitialSample: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: PinTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial active drawer is Today
    // Capture initial rested drawer top position
    final initialRestingTop = tester.getTopLeft(find.byKey(const ValueKey<TaskStatus>(TaskStatus.today))).dy;

    // Tap Backlog tab to trigger tab transition
    await tester.tap(find.text('Backlog'));
    await tester.pump(); // Advance to start animation frame

    // Advance 240ms into the 480ms transition (midpoint)
    await tester.pump(const Duration(milliseconds: 240));

    // Both sheets are present during the transition
    final outgoingFinder = find.byKey(const ValueKey<TaskStatus>(TaskStatus.today));
    final incomingFinder = find.byKey(const ValueKey<TaskStatus>(TaskStatus.backlog));
    expect(outgoingFinder, findsOneWidget);
    expect(incomingFinder, findsOneWidget);

    // Verify incoming drawer is midway down from tab slot (-72px) towards resting position
    final incomingTop = tester.getTopLeft(incomingFinder).dy;
    expect(incomingTop, lessThan(initialRestingTop));
    expect(incomingTop, greaterThan(initialRestingTop - 72.0));

    // Verify outgoing drawer has started shrinking (< 1.0)
    final outgoingScale = tester.widget<ScaleTransition>(
      find.ancestor(of: outgoingFinder, matching: find.byType(ScaleTransition)).first,
    );
    expect(outgoingScale.scale.value, lessThan(1.0));
    expect(outgoingScale.scale.value, greaterThanOrEqualTo(0.88));

    // Verify incoming drawer has started expanding towards 1.0
    final incomingScale = tester.widget<ScaleTransition>(
      find.ancestor(of: incomingFinder, matching: find.byType(ScaleTransition)).first,
    );
    expect(incomingScale.scale.value, greaterThan(0.88));
    expect(incomingScale.scale.value, lessThanOrEqualTo(1.0));

    // Verify incoming tab is fading in
    final incomingFade = tester.widget<FadeTransition>(
      find.ancestor(of: incomingFinder, matching: find.byType(FadeTransition)).first,
    );
    expect(incomingFade.opacity.value, greaterThan(0.0));
    expect(incomingFade.opacity.value, lessThanOrEqualTo(1.0));

    // Verify outgoing drawer is fading out
    final outgoingFade = tester.widget<FadeTransition>(
      find.ancestor(of: outgoingFinder, matching: find.byType(FadeTransition)).first,
    );
    expect(outgoingFade.opacity.value, greaterThan(0.0));
    expect(outgoingFade.opacity.value, lessThan(1.0));

    // Complete transition
    await tester.pumpAndSettle();

    // Only Backlog is active and resting at the standard drawer top position
    final finalFinder = find.byKey(const ValueKey<TaskStatus>(TaskStatus.backlog));
    expect(finalFinder, findsOneWidget);
    expect(find.byKey(const ValueKey<TaskStatus>(TaskStatus.today)), findsNothing);
    expect(tester.getTopLeft(finalFinder).dy, equals(initialRestingTop));

  });

  testWidgets('themeModeProvider defaults to ThemeMode.system', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}

