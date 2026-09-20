import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';

/// Helper functions for status titles, icons, and task list mapping in wide fold view.
class WideFoldHelpers {
  WideFoldHelpers._();

  /// Returns the human-readable display title for a given [status].
  static String statusTitle(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.today:
        return 'Today';
      case TaskStatus.done:
        return 'Done';
    }
  }

  /// Returns the standard icon representing a given [status].
  static IconData statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return Icons.inventory_2_outlined;
      case TaskStatus.today:
        return Icons.bolt_rounded;
      case TaskStatus.done:
        return Icons.check_circle_outline_rounded;
    }
  }

  /// Extracts the task list from [state] matching the given [status].
  static List<PinTask> tasksForStatus(TaskListState state, TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return state.backlogTasks;
      case TaskStatus.today:
        return state.todayTasks;
      case TaskStatus.done:
        return state.doneTasks;
    }
  }
}
