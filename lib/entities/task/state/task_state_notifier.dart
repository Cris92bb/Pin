import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/storage/prefs_storage_adapter.dart';
import '../../../shared/api/storage/storage_adapter.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/atomic_step.dart';
import '../model/pin_task.dart';

/// Immutable state containing the current tasks and active WIP configuration.
class TaskListState {
  final List<PinTask> tasks;
  final int wipLimit;
  final bool isLoading;
  final String? alertMessage;

  const TaskListState({
    this.tasks = const [],
    this.wipLimit = PinTokens.defaultWipLimit,
    this.isLoading = false,
    this.alertMessage,
  });

  List<PinTask> get todayTasks =>
      tasks.where((t) => t.status == TaskStatus.today).toList();

  List<PinTask> get backlogTasks =>
      tasks.where((t) => t.status == TaskStatus.backlog).toList();

  List<PinTask> get doneTasks =>
      tasks.where((t) => t.status == TaskStatus.done).toList();

  bool get isTodayWipFull => todayTasks.length >= wipLimit;

  int get todayCount => todayTasks.length;

  int get availableSlots => (wipLimit - todayCount).clamp(0, wipLimit);

  TaskListState copyWith({
    List<PinTask>? tasks,
    int? wipLimit,
    bool? isLoading,
    String? alertMessage,
    bool clearAlert = false,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      wipLimit: wipLimit ?? this.wipLimit,
      isLoading: isLoading ?? this.isLoading,
      alertMessage: clearAlert ? null : (alertMessage ?? this.alertMessage),
    );
  }
}

/// State notifier managing task (Pin) operations and strictly enforcing WIP limits.
class TaskStateNotifier extends StateNotifier<TaskListState> {
  final StorageAdapter storage;
  void Function(List<PinTask> tasks)? onTasksPersisted;

  TaskStateNotifier({
    required this.storage,
    int initialWipLimit = PinTokens.defaultWipLimit,
    bool seedInitialSample = false,
    this.onTasksPersisted,
  }) : super(TaskListState(wipLimit: initialWipLimit)) {
    loadTasks(seedIfEmpty: seedInitialSample);
  }

  /// Loads tasks from storage adapter; optionally seeds companion sample data if empty.
  Future<void> loadTasks({bool seedIfEmpty = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final taskMaps = await storage.loadTasks();
      if (taskMaps.isEmpty && seedIfEmpty) {
        final sampleTasks = _generateSamplePins();
        state = state.copyWith(tasks: sampleTasks, isLoading: false);
        await _persist();
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

  static List<PinTask> _generateSamplePins() {
    final now = DateTime.now();
    return [
      PinTask(
        id: 'sample-pin-1',
        title: 'Refactor drawer transition physics in UI',
        description:
            'Tune spring damping and stiffness for snappy tactile feel on mobile.',
        status: TaskStatus.today,
        isPinned: true,
        energyTag: 'medium-flow',
        estimatedMinutes: 30,
        tags: ['#dev', '#ui'],
        subtasks: [
          const AtomicStep(
            id: 's1-1',
            title: 'Audit current curve curves.easeInOut',
            isCompleted: true,
          ),
          const AtomicStep(
            id: 's1-2',
            title: 'Benchmark 60fps gesture response',
            isCompleted: false,
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      ),
      PinTask(
        id: 'sample-pin-2',
        title: 'Send project update email to team',
        description:
            'Brief 3-bullet summary of weekly achievements and blockers.',
        status: TaskStatus.today,
        isPinned: true,
        energyTag: 'low-friction',
        estimatedMinutes: 15,
        tags: ['#admin', '#quick-win'],
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
      ),
      PinTask(
        id: 'sample-pin-3',
        title: 'Draft architecture diagram for sync adapter',
        description: 'Export SVG for documentation repository.',
        status: TaskStatus.today,
        isPinned: true,
        energyTag: 'deep-focus',
        estimatedMinutes: 45,
        tags: ['#arch', '#docs'],
        createdAt: now.subtract(const Duration(minutes: 40)),
        updatedAt: now,
      ),
      PinTask(
        id: 'sample-pin-4',
        title: 'Investigate offline IndexedDB fallback for Web',
        description: 'Verify storage quotas and cross-origin isolation.',
        status: TaskStatus.backlog,
        isPinned: false,
        energyTag: 'deep-focus',
        estimatedMinutes: 60,
        tags: ['#web', '#storage'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      PinTask(
        id: 'sample-pin-5',
        title: 'Design app icon variations for smartphone home screen',
        description: 'Generate square and adaptive Android/iOS vectors.',
        status: TaskStatus.backlog,
        isPinned: false,
        energyTag: 'creative',
        estimatedMinutes: 30,
        tags: ['#design', '#mobile'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      PinTask(
        id: 'sample-pin-6',
        title: 'Setup automated GitHub Actions runner',
        description: 'Ensure tests run on every pull request.',
        status: TaskStatus.backlog,
        isPinned: false,
        energyTag: 'medium-flow',
        estimatedMinutes: 30,
        tags: ['#ci', '#devops'],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
      PinTask(
        id: 'sample-pin-7',
        title: 'Initial Flutter companion app scaffold',
        description: 'Setup base Riverpod container and FSD directory tree.',
        status: TaskStatus.done,
        isPinned: false,
        energyTag: 'low-friction',
        estimatedMinutes: 20,
        tags: ['#setup'],
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
        completedAt: now.subtract(const Duration(days: 3)),
      ),
      PinTask(
        id: 'sample-pin-8',
        title: 'Define design tokens and calm color palette',
        description: 'Curate dark slate and high contrast light mode tokens.',
        status: TaskStatus.done,
        isPinned: false,
        energyTag: 'creative',
        estimatedMinutes: 25,
        tags: ['#design'],
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
        completedAt: now.subtract(const Duration(days: 2)),
      ),
      PinTask(
        id: 'sample-pin-9',
        title: 'Unit test Base64 blueprint codec',
        description: 'Validate round-trip serialization and corruption guard.',
        status: TaskStatus.done,
        isPinned: false,
        energyTag: 'low-friction',
        estimatedMinutes: 15,
        tags: ['#test'],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
        completedAt: now.subtract(const Duration(days: 1)),
      ),
      PinTask(
        id: 'sample-pin-10',
        title: 'Implement atomic local storage adapter',
        description: 'Verify temporary swap mechanism for zero corruptions.',
        status: TaskStatus.done,
        isPinned: false,
        energyTag: 'deep-focus',
        estimatedMinutes: 40,
        tags: ['#storage'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        completedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  void dismissAlert() {
    if (state.alertMessage != null) {
      state = state.copyWith(clearAlert: true);
    }
  }

  /// Sets WIP limit between 4 and 5
  Future<void> setWipLimit(int limit) async {
    final clamped = limit.clamp(PinTokens.minWipLimit, PinTokens.maxWipLimit);
    state = state.copyWith(wipLimit: clamped);
  }

  /// Creates a new Pin.
  /// Rejects addition to Today if the WIP limit has been reached.
  Future<bool> createTask(PinTask task) async {
    if (task.status == TaskStatus.today && state.isTodayWipFull) {
      state = state.copyWith(
        alertMessage:
            'WIP Limit reached (${state.wipLimit}/${state.wipLimit})! Finish or move an active task before adding another.',
      );
      return false;
    }

    final updated = [task, ...state.tasks];
    state = state.copyWith(tasks: updated, clearAlert: true);
    await _persist();
    return true;
  }

  /// Moves a task into "Today", enforcing WIP constraints.
  Future<bool> moveToToday(String taskId) async {
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
    await _persist();
    return true;
  }

  /// Toggles Pin status: Pinning moves from Backlog to Today; Unpinning moves from Today to Backlog.
  Future<bool> togglePin(String taskId) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return false;

    final currentTask = state.tasks[taskIndex];
    if (currentTask.status == TaskStatus.today) {
      // Unpin: move to Backlog
      await moveToBacklog(taskId);
      return true;
    } else {
      // Pin: move to Today
      return await moveToToday(taskId);
    }
  }

  /// Moves a task into "Backlog".
  Future<void> moveToBacklog(String taskId) async {
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
    await _persist();
  }

  /// Moves a task into "Done".
  Future<void> moveToDone(String taskId) async {
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
    await _persist();
  }

  /// Updates an existing task.
  Future<bool> updateTask(PinTask updatedTask) async {
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
    await _persist();
    return true;
  }

  /// Deletes a task by ID.
  Future<void> deleteTask(String taskId) async {
    final updatedList = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(tasks: updatedList);
    await _persist();
  }

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
    await _persist();
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
    await _persist();
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
    await _persist();
  }

  /// Clears all Done tasks (Archive).
  Future<void> clearDoneTasks() async {
    final updatedList =
        state.tasks.where((t) => t.status != TaskStatus.done).toList();
    state = state.copyWith(tasks: updatedList);
    await _persist();
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
    await _persist();
  }

  /// Hydrates tasks from Cloud Firestore snapshot and updates local storage.
  Future<void> hydrateFromCloud(List<PinTask> cloudTasks) async {
    state = state.copyWith(tasks: cloudTasks);
    final taskMaps = cloudTasks.map((t) => t.toJson()).toList();
    try {
      await storage.saveTasks(taskMaps);
    } catch (_) {}
  }

  Future<void> _persist() async {
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

// Riverpod Providers
final storageAdapterProvider = Provider<StorageAdapter>((ref) {
  return PrefsStorageAdapter();
});

final taskStateProvider =
    StateNotifierProvider<TaskStateNotifier, TaskListState>((ref) {
  final storage = ref.watch(storageAdapterProvider);
  return TaskStateNotifier(storage: storage, seedInitialSample: true);
});

final activeFocusTaskProvider = StateProvider<PinTask?>((ref) => null);

/// Active deck tab in the layered companion view (Today, Backlog, or Done).
final activeDeckProvider = StateProvider<TaskStatus>((ref) => TaskStatus.today);

/// Theme mode provider: toggles between Light and Dark mode.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
