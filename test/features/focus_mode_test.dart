import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/atomic_step/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/focus_mode/ui/focus_mode_view.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

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
}
