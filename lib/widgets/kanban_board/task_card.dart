import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/task_crud/state/task_editor_state.dart';
import '../../shared/ui/pin_tokens.dart';
import 'components/task_card_metadata_row.dart';
import 'task_action_bubble.dart';

/// Tactile Pin card designed to match the companion app screenshot.
class TaskCard extends ConsumerStatefulWidget {
  final PinTask task;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    this.onEdit,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  Offset? _lastTapDownPosition;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = task.status == TaskStatus.done;
    final isToday = task.status == TaskStatus.today;

    final activeFocusTask = ref.watch(activeFocusTaskProvider);
    final isFocused = activeFocusTask?.id == task.id;
    final activeFocusColor =
        isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusCard,
        border: isFocused
            ? Border.all(
                color: activeFocusColor,
                width: 2.0,
              )
            : (isDark
                ? Border.all(
                    color: borderColor,
                    width: 1.6,
                  )
                : null),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: activeFocusColor.withValues(alpha: isDark ? 0.35 : 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isDark
                ? PinTokens.darkCardShadow
                : PinTokens.lightCardShadow),
      ),
      child: InkWell(
        borderRadius: PinTokens.radiusCard,
        onTapDown: (details) {
          _lastTapDownPosition = details.globalPosition;
        },
        onTap: () {
          // Select pin as focused and dismiss any active edit overlay
          ref.read(activeTaskEditorProvider.notifier).state = null;
          ref.read(activeFocusTaskProvider.notifier).state = task;
        },
        onLongPress: () {
          TaskActionBubble.show(
            context,
            task: task,
            targetPosition: _lastTapDownPosition,
            onEdit: widget.onEdit,
            onDelete: () {
              ref.read(taskStateProvider.notifier).deleteTask(task.id);
            },
          );
        },
        onSecondaryTapUp: (details) {
          TaskActionBubble.show(
            context,
            task: task,
            targetPosition: details.globalPosition,
            onEdit: widget.onEdit,
            onDelete: () {
              ref.read(taskStateProvider.notifier).deleteTask(task.id);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Pin toggle on left and status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // UNPIN / PIN Action on the left
                  IconButton(
                    icon: Icon(
                      isToday ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 16,
                      color: isToday
                          ? (isDark
                              ? PinTokens.darkActiveFocus
                              : PinTokens.lightActiveFocus)
                          : (isDark
                              ? PinTokens.darkTextTertiary
                              : PinTokens.lightTextTertiary),
                    ),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: isToday ? 'Unpin from Today' : 'Pin to Today',
                    onPressed: () {
                      ref.read(taskStateProvider.notifier).togglePin(task.id);
                    },
                  ),
                  const SizedBox(width: 4),

                  // Move to Done Action (green checkmark)
                  IconButton(
                    icon: Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.check_rounded,
                      size: 18,
                      color: PinTokens.accentEmerald,
                    ),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: isDone ? 'Move back to Today' : 'Move to Done',
                    onPressed: () {
                      final notifier = ref.read(taskStateProvider.notifier);
                      if (isDone) {
                        notifier.moveToToday(task.id);
                      } else {
                        notifier.moveToDone(task.id);
                      }
                    },
                  ),
                  // ACTIVE FOCUS status badge (only shown when task is currently focused)
                  if (isFocused) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ACTIVE FOCUS',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: activeFocusColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDone
                      ? (isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextTertiary)
                      : textPrimary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
                  height: 1.3,
                ),
              ),

              // Description
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDone
                        ? (isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary)
                        : textSecondary,
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Bottom Metadata Row: Energy Pill, Duration, and Hashtags
              TaskCardMetadataRow(
                task: task,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
