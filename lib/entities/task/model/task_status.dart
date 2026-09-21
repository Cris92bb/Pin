/// Status representation of a task across Kanban columns and views.
enum TaskStatus {
  backlog,
  today,
  done;

  /// User-visible display label for the column.
  String get label {
    switch (this) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.today:
        return 'Today';
      case TaskStatus.done:
        return 'Done';
    }
  }

  /// Parses a string representation from storage or sync into a [TaskStatus].
  static TaskStatus fromString(String? val) {
    switch (val) {
      case 'today':
      case 'in_progress':
        return TaskStatus.today;
      case 'completed':
      case 'done':
        return TaskStatus.done;
      case 'backlog':
      default:
        return TaskStatus.backlog;
    }
  }

  /// Converts the status into a persistent storage representation string.
  String toStorageString() {
    switch (this) {
      case TaskStatus.today:
        return 'today';
      case TaskStatus.done:
        return 'completed';
      case TaskStatus.backlog:
        return 'backlog';
    }
  }
}
