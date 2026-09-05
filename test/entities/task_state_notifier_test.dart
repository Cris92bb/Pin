import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/atomic_step/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/api/storage/memory_storage_adapter.dart';

void main() {
  group('TaskStateNotifier & WIP Limit Enforcement', () {
    late MemoryStorageAdapter storage;
    late TaskStateNotifier notifier;

    setUp(() {
      storage = MemoryStorageAdapter();
      notifier = TaskStateNotifier(storage: storage, initialWipLimit: 5);
    });

    test('initial state has default WIP limit of 5 and empty tasks', () {
      expect(notifier.state.wipLimit, 5);
      expect(notifier.state.todayTasks, isEmpty);
      expect(notifier.state.backlogTasks, isEmpty);
      expect(notifier.state.doneTasks, isEmpty);
    });

    test('enforces strict WIP limit of 5 for Today column', () async {
      // Add 5 tasks to Today
      for (int i = 1; i <= 5; i++) {
        final task = PinTask(
          id: 'task_$i',
          title: 'Task $i',
          status: TaskStatus.today,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await notifier.createTask(task);
        expect(result, isTrue);
      }

      expect(notifier.state.todayCount, 5);
      expect(notifier.state.isTodayWipFull, isTrue);

      // Attempt to add a 6th task to Today
      final task6 = PinTask(
        id: 'task_6',
        title: 'Task 6',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result6 = await notifier.createTask(task6);

      // Must be rejected!
      expect(result6, isFalse);
      expect(notifier.state.todayCount, 5);
      expect(notifier.state.alertMessage, contains('WIP Limit reached'));
    });

    test('allows adding tasks to Backlog even when Today is full', () async {
      // Fill Today up to 5
      for (int i = 1; i <= 5; i++) {
        final task = PinTask(
          id: 'today_$i',
          title: 'Today $i',
          status: TaskStatus.today,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await notifier.createTask(task);
      }

      // Add to Backlog
      final backlogTask = PinTask(
        id: 'backlog_1',
        title: 'Future Idea',
        status: TaskStatus.backlog,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await notifier.createTask(backlogTask);

      expect(result, isTrue);
      expect(notifier.state.backlogTasks.length, 1);
      expect(notifier.state.todayCount, 5);
    });

    test('moving task to Done frees up Today WIP capacity', () async {
      // Add 5 tasks to Today
      for (int i = 1; i <= 5; i++) {
        final task = PinTask(
          id: 't_$i',
          title: 'Task $i',
          status: TaskStatus.today,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await notifier.createTask(task);
      }
      expect(notifier.state.isTodayWipFull, isTrue);

      // Mark one done
      await notifier.moveToDone('t_1');
      expect(notifier.state.todayCount, 4);
      expect(notifier.state.doneTasks.length, 1);
      expect(notifier.state.isTodayWipFull, isFalse);

      // Now we can move another task into Today
      final newTodayTask = PinTask(
        id: 't_new',
        title: 'New Today Task',
        status: TaskStatus.today,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final res = await notifier.createTask(newTodayTask);
      expect(res, isTrue);
      expect(notifier.state.todayCount, 5);
    });

    test('WIP limit can be adjusted between 4 and 5', () async {
      await notifier.setWipLimit(4);
      expect(notifier.state.wipLimit, 4);

      // Should clamp outside bounds
      await notifier.setWipLimit(2);
      expect(notifier.state.wipLimit, 4);

      await notifier.setWipLimit(10);
      expect(notifier.state.wipLimit, 5);
    });

    test('logs focus time accurately into task trackedSeconds', () async {
      final task = PinTask(
        id: 'focus_t',
        title: 'Focus Task',
        status: TaskStatus.today,
        trackedSeconds: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await notifier.createTask(task);

      await notifier.logTimeSpent('focus_t', 90);

      final updated =
          notifier.state.tasks.firstWhere((t) => t.id == 'focus_t');
      expect(updated.trackedSeconds, 120);
    });

    test('toggles atomic subtask completion', () async {
      final task = PinTask(
        id: 'subtask_t',
        title: 'Subtask Task',
        status: TaskStatus.today,
        subtasks: const [
          AtomicStep(id: 's1', title: 'Step 1', isCompleted: false),
          AtomicStep(id: 's2', title: 'Step 2', isCompleted: false),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await notifier.createTask(task);

      await notifier.toggleSubtask('subtask_t', 's1', true);

      final updated =
          notifier.state.tasks.firstWhere((t) => t.id == 'subtask_t');
      expect(updated.subtasks.first.isCompleted, isTrue);
      expect(updated.subtasks.last.isCompleted, isFalse);
      expect(updated.completedSubtasksCount, 1);
      expect(updated.subtaskProgress, 0.5);
    });
  });
}
