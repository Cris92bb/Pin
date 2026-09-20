import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'wide_fold_inactive_drawer.dart';

/// The inactive pane displaying two dormant drawers side-by-side in WideFoldKanbanView.
class WideFoldInactivePane extends StatelessWidget {
  /// Global task list state.
  final TaskListState taskState;

  /// Whether the dark theme is active.
  final bool isDark;

  /// The two inactive statuses to display.
  final List<TaskStatus> inactiveStatuses;

  /// Callback when an inactive drawer is tapped to dock it to active position.
  final ValueChanged<TaskStatus> onSelectStatus;

  /// Creates a [WideFoldInactivePane].
  const WideFoldInactivePane({
    super.key,
    required this.taskState,
    required this.isDark,
    required this.inactiveStatuses,
    required this.onSelectStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: WideFoldInactiveDrawer(
            status: inactiveStatuses[0],
            taskState: taskState,
            isDark: isDark,
            onSelect: () => onSelectStatus(inactiveStatuses[0]),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: WideFoldInactiveDrawer(
            status: inactiveStatuses[1],
            taskState: taskState,
            isDark: isDark,
            onSelect: () => onSelectStatus(inactiveStatuses[1]),
          ),
        ),
      ],
    );
  }
}
