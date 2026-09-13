import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/task_crud/ui/task_crud_modal.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  testWidgets('TaskCrudModal empty title displays inline error on Pin to Deck', (tester) async {
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
        child: const MaterialApp(
          home: Scaffold(
            body: TaskCrudModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify modal rendered
    expect(find.text('Capture New Pin'), findsOneWidget);
    expect(find.text('Pin to Deck'), findsOneWidget);

    // Tap Pin to Deck without entering title
    await tester.tap(find.text('Pin to Deck'));
    await tester.pumpAndSettle();

    // Expect inline error to appear
    expect(find.text('Please enter a Pin title.'), findsOneWidget);
  });

  testWidgets('TaskCrudModal creates task and closes when valid', (tester) async {
    final fakeStorage = MemoryStorageAdapter();
    late TaskStateNotifier notifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(
            (ref) {
              notifier = TaskStateNotifier(
                storage: fakeStorage,
                seedInitialSample: false,
              );
              return notifier;
            },
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => TaskCrudModal.show(context),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Capture New Pin'), findsOneWidget);

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'My Brand New Pin');
    await tester.pumpAndSettle();

    // Tap Pin to Deck
    await tester.tap(find.text('Pin to Deck'));
    await tester.pumpAndSettle();

    // Modal should be closed
    expect(find.text('Capture New Pin'), findsNothing);

    // Task should be in notifier
    expect(notifier.state.tasks.any((t) => t.title == 'My Brand New Pin'), isTrue);
  });

  testWidgets(
      'TaskCrudModal shows WIP limit error when Today is 5/5 and user explicitly selects Today then taps Pin to Deck',
      (tester) async {
    final fakeStorage = MemoryStorageAdapter();
    final now = DateTime.now();
    final notifier = TaskStateNotifier(
      storage: fakeStorage,
      seedInitialSample: false,
    );
    await notifier.loadTasks();
    for (int i = 0; i < 5; i++) {
      await notifier.createTask(
        PinTask(
          id: 't_$i',
          title: 'Task $i',
          status: TaskStatus.today,
          energyTag: 'low-friction',
          estimatedMinutes: 15,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                // Force Today as defaultStatus to bypass the auto-redirect to
                // Backlog that initState applies when isTodayWipFull is true.
                onPressed: () =>
                    TaskCrudModal.show(context, defaultStatus: TaskStatus.today),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(notifier.state.isTodayWipFull, isTrue);

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'Sixth task');
    await tester.pumpAndSettle();

    // Tap Pin to Deck
    await tester.tap(find.text('Pin to Deck'));
    await tester.pumpAndSettle();

    // Modal should NOT be closed — WIP limit rejects the creation.
    expect(find.text('Capture New Pin'), findsOneWidget);

    // It should display the WIP limit error inline.
    expect(find.textContaining('WIP Limit reached'), findsOneWidget);
  });

  testWidgets('TaskCrudModal allows pinning to Backlog when Today is 5/5', (tester) async {
    final fakeStorage = MemoryStorageAdapter();
    final now = DateTime.now();
    final notifier = TaskStateNotifier(
      storage: fakeStorage,
      seedInitialSample: false,
    );
    await notifier.loadTasks();
    for (int i = 0; i < 5; i++) {
      await notifier.createTask(
        PinTask(
          id: 't_$i',
          title: 'Task $i',
          status: TaskStatus.today,
          energyTag: 'low-friction',
          estimatedMinutes: 15,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => TaskCrudModal.show(context),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Select Backlog
    await tester.tap(find.text('Backlog'));
    await tester.pumpAndSettle();

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'Backlog Task 1');
    await tester.pumpAndSettle();

    // Tap Pin to Deck
    await tester.tap(find.text('Pin to Deck'));
    await tester.pumpAndSettle();

    // Modal should close and task should be in backlog
    expect(find.text('Capture New Pin'), findsNothing);
    expect(notifier.state.backlogTasks.any((t) => t.title == 'Backlog Task 1'), isTrue);
  });
}


