import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Target deck / status selector component (Today, Backlog, Done) for TaskCrudModal.
class TaskCrudDeckSelector extends StatelessWidget {
  /// The currently selected status.
  final TaskStatus selectedStatus;

  /// Global task state for count badges.
  final TaskListState taskState;

  /// Whether the modal is in edit mode.
  final bool isEditing;

  /// Initial status if editing.
  final TaskStatus? initialStatus;

  /// Callback when a status is selected.
  final ValueChanged<TaskStatus> onStatusSelected;

  /// Creates a [TaskCrudDeckSelector].
  const TaskCrudDeckSelector({
    super.key,
    required this.selectedStatus,
    required this.taskState,
    required this.isEditing,
    this.initialStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Deck',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildColumnOption(
                context: context,
                label: 'Today',
                status: TaskStatus.today,
                badge: '${taskState.todayCount}/${taskState.wipLimit} focus',
                isFull: taskState.isTodayWipFull &&
                    initialStatus != TaskStatus.today,
              ),
              const SizedBox(width: 8),
              _buildColumnOption(
                context: context,
                label: 'Backlog',
                status: TaskStatus.backlog,
                badge: '${taskState.backlogTasks.length} queued',
              ),
              if (isEditing) ...[
                const SizedBox(width: 8),
                _buildColumnOption(
                  context: context,
                  label: 'Done',
                  status: TaskStatus.done,
                  badge: '${taskState.doneTasks.length} done',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumnOption({
    required BuildContext context,
    required String label,
    required TaskStatus status,
    required String badge,
    bool isFull = false,
  }) {
    final isSelected = selectedStatus == status;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon = status == TaskStatus.today
        ? Icons.bolt_rounded
        : (status == TaskStatus.done
            ? Icons.check_circle_outline_rounded
            : Icons.inventory_2_outlined);

    final bgCol = isSelected
        ? (isDark ? PinTokens.darkSheetBgAlt : PinTokens.lightSheetBg)
        : (isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg);

    final borderCol = isSelected
        ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg)
        : (isDark ? PinTokens.darkBorder : PinTokens.lightBorder);

    final iconCol = isSelected
        ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg)
        : (isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary);

    final labelCol = isSelected
        ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightFabBg)
        : (isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary);

    final badgeCol = isFull
        ? PinTokens.accentAmber
        : (isSelected
            ? (isDark
                ? PinTokens.darkActiveFocus
                : PinTokens.lightTextSecondary)
            : (isDark
                ? PinTokens.darkTextMuted
                : PinTokens.lightTextSecondary));

    return Expanded(
      child: InkWell(
        onTap: () => onStatusSelected(status),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: PinTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderCol,
              width: isSelected ? 1.2 : 1.0,
            ),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: PinTokens.shadowForest.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: iconCol,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: labelCol,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeCol,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
