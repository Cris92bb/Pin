import '../model/atomic_step.dart';
import '../model/pin_task.dart';
import 'task_notifier.dart';

/// Extension providing subtask, focus time tracking, and import/export mutations
/// for [TaskStateNotifier].
extension TaskMutations on TaskStateNotifier {
  /// Toggles an atomic subtask completion state.
  Future<void> toggleSubtask(String taskId, String subtaskId, bool isCompleted) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    final updatedSubtasks = task.subtasks.map((step) {
      if (step.id == subtaskId) {
        return step.copyWith(isCompleted: isCompleted);
      }
      return step;
    }).toList();

    final updatedTask = task.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList);
    await persist();
  }

  /// Adds an atomic subtask to a task.
  Future<void> addSubtask(String taskId, AtomicStep step) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    final updatedSubtasks = [...task.subtasks, step];

    final updatedTask = task.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList);
    await persist();
  }

  /// Logs time spent (seconds) in Focus Mode.
  Future<void> logTimeSpent(String taskId, int additionalSeconds) async {
    if (additionalSeconds <= 0) return;

    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    final updatedTask = task.copyWith(
      trackedSeconds: task.trackedSeconds + additionalSeconds,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList);
    await persist();
  }

  /// Clears all Done tasks (Archive).
  Future<void> clearDoneTasks() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final t in state.tasks) {
      if (t.status == TaskStatus.done) {
        recordTaskDeleted(t.id, timestamp: now);
      }
    }
    final updatedList =
        state.tasks.where((t) => t.status != TaskStatus.done).toList();
    state = state.copyWith(tasks: updatedList);
    await persist();
  }

  /// Imports a batch of tasks from blueprint decoding.
  Future<void> importTasks(List<PinTask> incomingTasks, {bool replaceAll = false}) async {
    if (replaceAll) {
      state = state.copyWith(tasks: incomingTasks);
    } else {
      final Map<String, PinTask> map = {for (final t in state.tasks) t.id: t};
      for (final t in incomingTasks) {
        map[t.id] = t;
      }
      state = state.copyWith(tasks: map.values.toList());
    }
    await persist();
  }

  /// Hydrates tasks from Cloud Firestore snapshot and updates local storage.
  Future<void> hydrateFromCloud(List<PinTask> cloudTasks) async {
    state = state.copyWith(tasks: cloudTasks);
    final taskMaps = cloudTasks.map((t) => t.toJson()).toList();
    try {
      await storage.saveTasks(taskMaps);
    } catch (_) {}
  }
}
