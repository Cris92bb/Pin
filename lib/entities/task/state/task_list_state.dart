import '../../../shared/ui/pin_tokens.dart';
import '../model/pin_task.dart';

/// Immutable state containing current tasks, active board filter, and WIP limit.
class TaskListState {
  final List<PinTask> tasks;
  final String activeBoardId;
  final int wipLimit;
  final bool isLoading;
  final String? alertMessage;

  const TaskListState({
    this.tasks = const [],
    this.activeBoardId = 'personal',
    this.wipLimit = PinTokens.defaultWipLimit,
    this.isLoading = false,
    this.alertMessage,
  });

  /// Tasks currently assigned to the Today column for the active board.
  List<PinTask> get todayTasks => tasks
      .where((t) => t.status == TaskStatus.today && t.boardId == activeBoardId)
      .toList();

  /// Tasks currently residing in the Backlog column for the active board.
  List<PinTask> get backlogTasks => tasks
      .where((t) => t.status == TaskStatus.backlog && t.boardId == activeBoardId)
      .toList();

  /// Tasks marked as Done for the active board.
  List<PinTask> get doneTasks => tasks
      .where((t) => t.status == TaskStatus.done && t.boardId == activeBoardId)
      .toList();

  /// Returns all tasks belonging to a specific board identifier.
  List<PinTask> tasksForBoard(String boardId) =>
      tasks.where((t) => t.boardId == boardId).toList();

  /// Whether the Today column has reached or exceeded the configured WIP limit.
  bool get isTodayWipFull => todayTasks.length >= wipLimit;

  /// Current number of tasks in Today for the active board.
  int get todayCount => todayTasks.length;

  /// Available task slots remaining in Today before reaching the WIP limit.
  int get availableSlots => (wipLimit - todayCount).clamp(0, wipLimit);

  /// Creates a copy of this state with updated fields.
  TaskListState copyWith({
    List<PinTask>? tasks,
    String? activeBoardId,
    int? wipLimit,
    bool? isLoading,
    String? alertMessage,
    bool clearAlert = false,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      activeBoardId: activeBoardId ?? this.activeBoardId,
      wipLimit: wipLimit ?? this.wipLimit,
      isLoading: isLoading ?? this.isLoading,
      alertMessage: clearAlert ? null : (alertMessage ?? this.alertMessage),
    );
  }
}
