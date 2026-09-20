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
  bool _isHovered = false;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
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
                // Unified Title Row: Circular Checkbox on left, Title in middle, Pushpin on top right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dedicated circular checkbox aligned with first line of title
                    Padding(
                      padding: const EdgeInsets.only(top: 1, right: 10),
                      child: Tooltip(
                        message: isDone ? 'Move back to Today' : 'Move to Done',
                        child: InkResponse(
                          radius: 16,
                          onTap: () {
                            final notifier = ref.read(taskStateProvider.notifier);
                            if (isDone) {
                              notifier.moveToToday(task.id);
                            } else {
                              notifier.moveToDone(task.id);
                            }
                          },
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: Center(
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone
                                      ? PinTokens.accentEmerald
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isDone
                                        ? PinTokens.accentEmerald
                                        : (isDark
                                            ? PinTokens.darkTextTertiary
                                            : PinTokens.lightTextTertiary),
                                    width: 1.6,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Title
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDone
                                ? (isDark
                                    ? PinTokens.darkTextSecondary
                                    : PinTokens.lightTextTertiary)
                                : textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            decorationColor: isDark
                                ? PinTokens.darkTextMuted
                                : PinTokens.lightTextTertiary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    // Subtle pushpin icon tucked into top-right corner, perfectly aligned
                    Padding(
                      padding: const EdgeInsets.only(top: 1, left: 6),
                      child: Tooltip(
                        message: isToday ? 'Unpin from Today' : 'Pin to Today',
                        child: InkResponse(
                          radius: 16,
                          onTap: () {
                            ref.read(taskStateProvider.notifier).togglePin(task.id);
                          },
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: Center(
                              child: Icon(
                                isToday ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                size: 16,
                                color: isToday
                                    ? PinTokens.accentViolet
                                    : (isDark
                                            ? PinTokens.darkTextTertiary
                                            : PinTokens.lightTextTertiary)
                                        .withValues(alpha: _isHovered ? 0.85 : 0.35),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    ),
  );
}
}
