import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin/app/theme/pin_theme.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/features/task_export_import/ui/import_shared_pin_modal.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  testWidgets('ImportSharedPinModal renders preview and imports task to selected status', (tester) async {
    final fakeStorage = MemoryStorageAdapter();
    final notifier = TaskStateNotifier(storage: fakeStorage, seedInitialSample: false);

    final now = DateTime(2026, 9, 21, 10, 0);
    final incomingTask = PinTask(
      id: 'shared-pin-101',
      title: 'Shared Deep Link Pin',
      description: 'Incoming from a friend via deep link',
      status: TaskStatus.backlog,
      category: 'deep_work',
      energyTag: 'deep-focus',
      intensity: 'focus',
      source: 'manual',
      estimatedMinutes: 25,
      trackedSeconds: 0,
      isPinned: false,
      tags: const ['collab'],
      subtasks: const [
        AtomicStep(id: 's1', title: 'Open the link', isCompleted: true),
        AtomicStep(id: 's2', title: 'Complete the pin', isCompleted: false),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(fakeStorage),
          taskStateProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          theme: PinTheme.darkTheme,
          home: Scaffold(
            body: ImportSharedPinModal(tasks: [incomingTask]),
          ),
        ),
      ),
    );

    // Verify task details are rendered
    expect(find.text('Shared Pin Received'), findsOneWidget);
    expect(find.text('Shared Deep Link Pin'), findsOneWidget);
    expect(find.text('25m estimate'), findsOneWidget);
    expect(find.text('Incoming from a friend via deep link'), findsOneWidget);
    expect(find.text('Open the link'), findsOneWidget);
    expect(find.text('Complete the pin'), findsOneWidget);

    // Select Backlog pill
    await tester.tap(find.text('Backlog'));
    await tester.pumpAndSettle();

    // Tap import button
    expect(find.text('Import to Backlog'), findsOneWidget);
    await tester.tap(find.text('Import to Backlog'));
    await tester.pumpAndSettle();

    // Verify task was added to notifier
    final state = notifier.state;
    expect(state.tasks.any((t) => t.id == 'shared-pin-101'), isTrue);
    final imported = state.tasks.firstWhere((t) => t.id == 'shared-pin-101');
    expect(imported.status, equals(TaskStatus.backlog));
  });
}
