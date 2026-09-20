import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/widgets/kanban_board/task_card.dart';

void main() {
  final testTask = PinTask(
    id: 'test_task_card_1',
    title: 'PIN: unfolded view single task',
    description: 'the complete pin delete shortcuts need some...',
    status: TaskStatus.today,
    energyTag: 'deep-focus',
    estimatedMinutes: 30,
    tags: ['#dev', '#design'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('TaskCard renders circular checkbox on left and pin on top-right without ACTIVE FOCUS badge', (tester) async {
    final fakeStorage = MemoryStorageAdapter([testTask.toJson()]);

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
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: TaskCard(task: testTask),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title is rendered
    expect(find.text('PIN: unfolded view single task'), findsOneWidget);

    // Verify circular checkbox exists (Move to Done)
    expect(find.byTooltip('Move to Done'), findsOneWidget);

    // Verify pushpin exists (Unpin from Today)
    expect(find.byTooltip('Unpin from Today'), findsOneWidget);

    // Verify circular checkbox and pushpin are precisely vertically aligned
    final checkboxTop = tester.getTopLeft(find.byTooltip('Move to Done')).dy;
    final pinTop = tester.getTopLeft(find.byTooltip('Unpin from Today')).dy;
    expect(checkboxTop, equals(pinTop));

    // Verify "ACTIVE FOCUS" badge is NOT rendered
    expect(find.text('ACTIVE FOCUS'), findsNothing);
  });

  testWidgets('Tapping circular checkbox completes task and toggles to done state', (tester) async {
    final fakeStorage = MemoryStorageAdapter([testTask.toJson()]);
    late WidgetRef capturedRef;

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
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            final tasks = ref.watch(taskStateProvider).tasks;
            final currentTask = tasks.isNotEmpty ? tasks.first : testTask;
            return MaterialApp(
              theme: PinTheme.darkTheme,
              home: Scaffold(
                body: TaskCard(task: currentTask),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap circular checkbox to move to Done
    await tester.tap(find.byTooltip('Move to Done'));
    await tester.pumpAndSettle();

    // Verify task moved to Done
    expect(capturedRef.read(taskStateProvider).doneTasks.length, 1);
    expect(find.byTooltip('Move back to Today'), findsOneWidget);
  });

  testWidgets('Tapping pushpin toggles pin status', (tester) async {
    final fakeStorage = MemoryStorageAdapter([testTask.toJson()]);
    late WidgetRef capturedRef;

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
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            final tasks = ref.watch(taskStateProvider).tasks;
            final currentTask = tasks.isNotEmpty ? tasks.first : testTask;
            return MaterialApp(
              theme: PinTheme.darkTheme,
              home: Scaffold(
                body: TaskCard(task: currentTask),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially pinned (status is today)
    final unpinButton = find.byTooltip('Unpin from Today');
    expect(unpinButton, findsOneWidget);

    // Tap to unpin
    await tester.tap(unpinButton);
    await tester.pumpAndSettle();

    // Verify now unpinned (moves to inbox/later)
    expect(find.byTooltip('Pin to Today'), findsOneWidget);
    expect(capturedRef.read(taskStateProvider).todayTasks, isEmpty);
  });
}
