import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'layered_deck_header.dart';
import 'layered_deck_task_list.dart';

/// Active foreground sheet container with border, shadow, header, and task list.
class LayeredDeckActiveSheet extends StatelessWidget {
  /// Active deck status.
  final TaskStatus activeDeck;

  /// Global task list state.
  final TaskListState state;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Card background color.
  final Color cardBg;

  /// Border color.
  final Color borderColor;

  /// Primary text color.
  final Color textPrimary;

  /// Secondary text color.
  final Color textSecondary;

  /// Callback when user navigates drawers horizontally.
  final ValueChanged<int> onNavigateDrawer;

  /// Creates a [LayeredDeckActiveSheet].
  const LayeredDeckActiveSheet({
    super.key,
    required this.activeDeck,
    required this.state,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onNavigateDrawer,
  });

  List<PinTask> _getTasksForDeck(TaskListState state, TaskStatus status) {
    switch (status) {
      case TaskStatus.today:
        return state.todayTasks;
      case TaskStatus.backlog:
        return state.backlogTasks;
      case TaskStatus.done:
        return state.doneTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : PinTokens.shadowSlate)
                .withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayeredDeckHeader(
              activeDeck: activeDeck,
              state: state,
              isDark: isDark,
              textPrimary: textPrimary,
              onNavigateDrawer: onNavigateDrawer,
            ),
            Expanded(
              child: LayeredDeckTaskList(
                key: ValueKey('drawer_tasks_${activeDeck.name}'),
                tasks: _getTasksForDeck(state, activeDeck),
                activeDeck: activeDeck,
                isDark: isDark,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
