import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/storage/prefs_storage_adapter.dart';
import '../../../shared/api/storage/storage_adapter.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/pin_task.dart';
import 'sample_pins.dart';
import 'task_list_state.dart';

/// State notifier managing task (Pin) operations and strictly enforcing WIP limits.
///
/// Implemented as a modern Riverpod [Notifier] while maintaining seamless standalone
/// test instantiation compatibility.
class TaskStateNotifier extends Notifier<TaskListState> {
  final StorageAdapter? _configuredStorage;
  final int _initialWipLimit;
  final bool _seedInitialSample;
  StorageAdapter? _storage;

  void Function(List<PinTask> tasks)? onTasksPersisted;
  final Map<String, int> _deletedTaskIds = {};
  TaskListState? _standaloneState;

  /// Map of deleted task IDs with deletion timestamps (tombstones).
  Map<String, int> get deletedTaskIds => Map.unmodifiable(_deletedTaskIds);

  /// Active storage adapter.
  StorageAdapter get storage => _storage ?? _configuredStorage ?? PrefsStorageAdapter();

  /// Future tracking the task loading operation.
  Future<void> loadFuture = Future.value();

  TaskStateNotifier({
    StorageAdapter? storage,
    int initialWipLimit = PinTokens.defaultWipLimit,
    bool seedInitialSample = false,
    this.onTasksPersisted,
  })  : _configuredStorage = storage,
        _initialWipLimit = initialWipLimit,
        _seedInitialSample = seedInitialSample;

  @override
  TaskListState build() {
    StorageAdapter? watchedStorage;
    try {
      watchedStorage = ref.watch(storageAdapterProvider);
    } catch (_) {}
    _storage = _configuredStorage ?? watchedStorage ?? PrefsStorageAdapter();
    final initialState = TaskListState(wipLimit: _initialWipLimit);
    _standaloneState = initialState;
    loadFuture = Future.microtask(() => loadTasks(seedIfEmpty: _seedInitialSample));
    return initialState;
  }

  @override
  TaskListState get state {
    try {
      return super.state;
    } catch (_) {
      return _standaloneState ??= TaskListState(wipLimit: _initialWipLimit);
    }
  }

  @override
  set state(TaskListState value) {
    try {
      super.state = value;
    } catch (_) {
      _standaloneState = value;
    }
  }

  /// Records a task deletion tombstone.
  void recordTaskDeleted(String taskId, {int? timestamp}) {
    _deletedTaskIds[taskId] = timestamp ?? DateTime.now().millisecondsSinceEpoch;
  }

  /// Merges external deletion tombstones into the local tombstone registry.
  void mergeDeletedTaskIds(Map<String, int> incoming) {
    for (final entry in incoming.entries) {
      final existing = _deletedTaskIds[entry.key];
      if (existing == null || entry.value > existing) {
        _deletedTaskIds[entry.key] = entry.value;
      }
    }
  }

  /// Returns true if this task is an unedited default sample pin generated on first launch.
  static bool isUntouchedSamplePin(PinTask task) {
    if (!task.id.startsWith('sample-pin-')) return false;
    final defaultTitle = defaultSampleTitles[task.id];
    return defaultTitle == task.title;
  }

  /// Loads tasks from storage adapter; optionally seeds companion sample data if empty.
  Future<void> loadTasks({bool seedIfEmpty = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final taskMaps = await storage.loadTasks();
      if (taskMaps.isEmpty && seedIfEmpty) {
        final sampleTasks = generateSamplePins();
        state = state.copyWith(tasks: sampleTasks, isLoading: false);
        await persist();
      } else {
        final loaded = taskMaps.map((m) => PinTask.fromJson(m)).toList();
        state = state.copyWith(tasks: loaded, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        alertMessage: 'Failed to load pins: ${e.toString()}',
      );
    }
  }

  /// Dismisses active alert banner.
  void dismissAlert() {
    if (state.alertMessage != null) {
      state = state.copyWith(clearAlert: true);
    }
  }

  /// Changes the active board workspace.
  void setActiveBoard(String boardId, {int? wipLimit}) {
    state = state.copyWith(
      activeBoardId: boardId,
      wipLimit: wipLimit ?? state.wipLimit,
    );
  }

  /// Sets WIP limit between min and max tokens.
  Future<void> setWipLimit(int limit) async {
    state = state.copyWith(wipLimit: limit.clamp(PinTokens.minWipLimit, PinTokens.maxWipLimit));
  }

  /// Creates a new Pin.
  /// Rejects addition to Today if the WIP limit has been reached.
  Future<bool> createTask(PinTask task) async {
    await loadFuture;
    final effective = task.boardId.isEmpty
        ? task.copyWith(boardId: state.activeBoardId)
        : task;
    if (effective.status == TaskStatus.today && state.isTodayWipFull) {
      state = state.copyWith(
        alertMessage:
            'WIP Limit reached (${state.wipLimit}/${state.wipLimit})! Finish or move an active task before adding another.',
      );
      return false;
    }

    final updated = [effective, ...state.tasks];
    state = state.copyWith(tasks: updated, clearAlert: true);
    await persist();
    return true;
  }

  /// Moves a task to a target board.
  Future<void> moveTaskToBoard(String taskId, String targetBoardId) async {
    await loadFuture;
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final currentTask = state.tasks[taskIndex];
    final updatedTask = currentTask.copyWith(
      boardId: targetBoardId,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList, clearAlert: true);
    await persist();
  }

  /// Moves a task into "Today", enforcing WIP constraints.
  Future<bool> moveToToday(String taskId) async {
    await loadFuture;
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return false;

    final currentTask = state.tasks[taskIndex];
    if (currentTask.status == TaskStatus.today) return true;

    if (state.isTodayWipFull) {
      state = state.copyWith(
        alertMessage:
            'WIP Limit reached (${state.wipLimit}/${state.wipLimit})! Focus on existing tasks or move one to Backlog first.',
      );
      return false;
    }

    final updatedTask = currentTask.copyWith(
      status: TaskStatus.today,
      isPinned: true,
      updatedAt: DateTime.now(),
      clearCompletedAt: true,
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList, clearAlert: true);
    await persist();
    return true;
  }

  /// Toggles Pin status: Pinning moves from Backlog to Today; Unpinning moves from Today to Backlog.
  Future<bool> togglePin(String taskId) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return false;
    final currentTask = state.tasks[taskIndex];
    if (currentTask.status == TaskStatus.today) {
      await moveToBacklog(taskId);
      return true;
    }
    return await moveToToday(taskId);
  }

  /// Moves a task into "Backlog".
  Future<void> moveToBacklog(String taskId) async {
    await loadFuture;
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final currentTask = state.tasks[taskIndex];
    final updatedTask = currentTask.copyWith(
      status: TaskStatus.backlog,
      isPinned: false,
      updatedAt: DateTime.now(),
      clearCompletedAt: true,
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList, clearAlert: true);
    await persist();
  }

  /// Moves a task into "Done".
  Future<void> moveToDone(String taskId) async {
    await loadFuture;
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final currentTask = state.tasks[taskIndex];
    final updatedTask = currentTask.copyWith(
      status: TaskStatus.done,
      isPinned: false,
      updatedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedList, clearAlert: true);
    await persist();
  }

  /// Updates an existing task.
  Future<bool> updateTask(PinTask updatedTask) async {
    await loadFuture;
    final taskIndex = state.tasks.indexWhere((t) => t.id == updatedTask.id);
    if (taskIndex == -1) return false;

    final oldTask = state.tasks[taskIndex];
    if (oldTask.status != TaskStatus.today &&
        updatedTask.status == TaskStatus.today &&
        state.isTodayWipFull) {
      state = state.copyWith(
        alertMessage:
            'Cannot move to Today: WIP Limit (${state.wipLimit}) reached.',
      );
      return false;
    }

    final finalTask = updatedTask.copyWith(updatedAt: DateTime.now());
    final updatedList = List<PinTask>.from(state.tasks)..[taskIndex] = finalTask;
    state = state.copyWith(tasks: updatedList, clearAlert: true);
    await persist();
    return true;
  }

  /// Deletes a task by ID.
  Future<void> deleteTask(String taskId) async {
    await loadFuture;
    recordTaskDeleted(taskId);
    final updatedList = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(tasks: updatedList);
    await persist();
  }

  /// Persists current tasks to local storage and invokes persistence hooks.
  Future<void> persist() async {
    try {
      final taskMaps = state.tasks.map((t) => t.toJson()).toList();
      await storage.saveTasks(taskMaps);
      onTasksPersisted?.call(state.tasks);
    } catch (e) {
      state = state.copyWith(
        alertMessage: 'Failed to save pins: ${e.toString()}',
      );
    }
  }
}
