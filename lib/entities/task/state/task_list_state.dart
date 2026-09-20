import '../../../shared/ui/pin_tokens.dart';
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

  /// Tasks currently assigned to the Today column.
  List<PinTask> get todayTasks =>
      tasks.where((t) => t.status == TaskStatus.today).toList();

  /// Tasks currently residing in the Backlog column.
  List<PinTask> get backlogTasks =>
      tasks.where((t) => t.status == TaskStatus.backlog).toList();

  /// Tasks marked as Done.
  List<PinTask> get doneTasks =>
      tasks.where((t) => t.status == TaskStatus.done).toList();

  /// Whether the Today column has reached or exceeded the configured WIP limit.
  bool get isTodayWipFull => todayTasks.length >= wipLimit;

  /// Current number of tasks in Today.
  int get todayCount => todayTasks.length;

  /// Available task slots remaining in Today before reaching the WIP limit.
  int get availableSlots => (wipLimit - todayCount).clamp(0, wipLimit);

  /// Creates a copy of this state with updated fields.
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
