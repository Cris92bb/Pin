import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/ai/ui/ai_task_breakdown_modal.dart';
import 'package:pin/features/task_crud/ui/task_crud_modal.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';
import 'package:pin/widgets/kanban_board/task_action_bubble.dart';
import 'package:pin/widgets/kanban_board/task_card.dart';

void main() {
  final testTask = PinTask(
    id: 'test_task_1',
    title: 'Design high-converting landing page',
    description: 'Hero section, testimonials, and interactive pricing tier',
    status: TaskStatus.today,
    energyTag: 'deep-focus',
    estimatedMinutes: 30,
    tags: ['#design', '#landing'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('TaskActionBubble renders AI Breakdown, Edit Pin, and Delete options', (tester) async {
    bool aiClicked = false;
    bool editClicked = false;
    bool deleteClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PinTheme.darkTheme,
        home: Scaffold(
          body: TaskActionBubble(
            task: testTask,
            onAiBreakdown: () => aiClicked = true,
            onEdit: () => editClicked = true,
            onDelete: () => deleteClicked = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Breakdown'), findsOneWidget);
    expect(find.text('Re-analyze'), findsOneWidget);
    expect(find.text('Edit Pin'), findsOneWidget);
    expect(find.text('Full editor'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Remove pin'), findsOneWidget);

    // Tap AI Breakdown
    await tester.tap(find.text('AI Breakdown'));
    await tester.pumpAndSettle();
    expect(aiClicked, isTrue);

    // Tap Edit Pin
    await tester.tap(find.text('Edit Pin'));
    await tester.pumpAndSettle();
    expect(editClicked, isTrue);

    // Tap Delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleteClicked, isTrue);
  });

  testWidgets('Long-pressing TaskCard opens TaskActionBubble modal', (tester) async {
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
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: TaskCard(task: testTask),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify task title is rendered
    expect(find.text('Design high-converting landing page'), findsOneWidget);

    // Long press the card
    await tester.longPress(find.byType(TaskCard));
    await tester.pumpAndSettle();

    // Verify TaskActionBubble popped up
    expect(find.byType(TaskActionBubble), findsOneWidget);
    expect(find.text('AI Breakdown'), findsOneWidget);
    expect(find.text('Edit Pin'), findsOneWidget);
  });

  testWidgets('Right-clicking (secondary click) TaskCard opens TaskActionBubble', (tester) async {
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
          home: Scaffold(
            body: TaskCard(task: testTask),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Secondary click (right click)
    await tester.tap(find.byType(TaskCard), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(find.byType(TaskActionBubble), findsOneWidget);
  });

  testWidgets('Tapping Edit Pin in TaskActionBubble opens TaskCrudModal', (tester) async {
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
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: TaskCard(task: testTask),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Long press to open bubble
    await tester.longPress(find.byType(TaskCard));
    await tester.pumpAndSettle();

    // Tap Edit Pin in bubble
    await tester.tap(find.text('Edit Pin'));
    await tester.pumpAndSettle();

    // Verify TaskCrudModal opened in edit mode
    expect(find.byType(TaskCrudModal), findsOneWidget);
    expect(find.text('Edit Pin'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TaskCrudModal),
        matching: find.text('Design high-converting landing page'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tapping AI Breakdown in TaskActionBubble launches breakdown modal', (tester) async {
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
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: TaskCard(task: testTask),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Long press to open bubble
    await tester.longPress(find.byType(TaskCard));
    await tester.pumpAndSettle();

    // Tap AI Breakdown in bubble
    await tester.tap(find.text('AI Breakdown'));
    await tester.pump();

    // Verify AiTaskBreakdownModal opened
    expect(find.byType(AiTaskBreakdownModal), findsOneWidget);
  });

  testWidgets('Tapping Delete in TaskActionBubble removes task from board', (tester) async {
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

    // Verify card is rendered
    expect(find.text('Design high-converting landing page'), findsOneWidget);

    // Long press to open bubble
    await tester.longPress(find.byType(TaskCard));
    await tester.pumpAndSettle();

    // Tap Delete in bubble
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Bubble is dismissed
    expect(find.byType(TaskActionBubble), findsNothing);
  });
}
