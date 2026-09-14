import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../shared/ui/pin_tokens.dart';
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
        border: isDark
            ? Border.all(
                color: borderColor,
                width: 1.6,
              )
            : null,
        boxShadow: isDark
            ? PinTokens.darkCardShadow
            : PinTokens.lightCardShadow,
      ),
      child: InkWell(
        borderRadius: PinTokens.radiusCard,
        onTapDown: (details) {
          _lastTapDownPosition = details.globalPosition;
        },
        onTap: () {
          // Tap card to enter immersive Focus Mode
          ref.read(activeFocusTaskProvider.notifier).state = task;
        },
        onLongPress: () {
          TaskActionBubble.show(
            context,
            task: task,
            targetPosition: _lastTapDownPosition,
            onEdit: widget.onEdit,
          );
        },
        onSecondaryTapUp: (details) {
          TaskActionBubble.show(
            context,
            task: task,
            targetPosition: details.globalPosition,
            onEdit: widget.onEdit,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Check circle, status badge, pin toggle, and delete
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Radio / Checkbox circle
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final notifier = ref.read(taskStateProvider.notifier);
                      if (isDone) {
                        notifier.moveToToday(task.id);
                      } else {
                        notifier.moveToDone(task.id);
                      }
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? (isDark ? PinTokens.darkTextPrimary : PinTokens.lightFabBg)
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? (isDark ? PinTokens.darkTextPrimary : PinTokens.lightFabBg)
                              : (isDark ? PinTokens.darkTextTertiary : PinTokens.lightTextTertiary),
                          width: 1.5,
                        ),
                      ),
                      child: isDone
                          ? Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: isDark ? PinTokens.darkCardBg : Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ACTIVE FOCUS status badge
                  Text(
                    isToday
                        ? 'ACTIVE FOCUS'
                        : (isDone ? 'COMPLETED' : 'BACKLOG'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isToday
                          ? (isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus)
                          : (isDone ? PinTokens.accentEmerald : (isDark ? PinTokens.darkTextMuted : PinTokens.lightTextSecondary)),
                    ),
                  ),

                  const Spacer(),

                  // UNPIN / PIN Action
                  InkWell(
                    borderRadius: PinTokens.radiusSm,
                    onTap: () {
                      ref.read(taskStateProvider.notifier).togglePin(task.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isToday ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                            size: 14,
                            color: isDark ? PinTokens.darkTextTertiary : PinTokens.lightTextTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isToday ? 'UNPIN' : 'PIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isDark
                                  ? PinTokens.darkTextTertiary
                                  : PinTokens.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Delete trash icon
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: isDark ? PinTokens.darkTextTertiary : PinTokens.lightTextTertiary,
                    ),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Delete Pin',
                    onPressed: () {
                      ref.read(taskStateProvider.notifier).deleteTask(task.id);
                    },
                  ),
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
                      ? (isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary)
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Energy Pill
                  _buildEnergyPill(task, isDark),

                  // Duration Pill
                  _buildDurationPill(task, isDark),

                  // Tracked time counter (if any)
                  if (task.trackedSeconds > 0)
                    _buildTrackedPill(task, isDark),

                  // Hashtag chips
                  for (final tag in task.tags)
                    _buildTagChip(tag, isDark),

                  // Subtasks indicator
                  if (task.hasSubtasks)
                    _buildSubtasksPill(task, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyPill(PinTask task, bool isDark) {
    Color bg;
    Color textColor;

    final lower = task.energyTag.toLowerCase();
    if (lower.contains('deep') || lower.contains('focus')) {
      bg = isDark ? PinTokens.darkEnergyFocusBg : PinTokens.energyDeepBg;
      textColor = isDark ? PinTokens.darkEnergyFocusText : PinTokens.energyDeepText;
    } else if (lower.contains('medium') || lower.contains('flow')) {
      bg = isDark ? PinTokens.darkEnergyMediumBg : PinTokens.energyMediumBg;
      textColor = isDark ? PinTokens.darkEnergyMediumText : PinTokens.energyMediumText;
    } else if (lower.contains('creative')) {
      bg = isDark ? const Color(0xFF2D2311) : PinTokens.energyCreativeBg;
      textColor = isDark ? const Color(0xFFFCD34D) : PinTokens.energyCreativeText;
    } else if (lower.contains('admin')) {
      bg = isDark ? const Color(0xFF1F2432) : PinTokens.energyAdminBg;
      textColor = isDark ? const Color(0xFF94A3B8) : PinTokens.energyAdminText;
    } else {
      bg = isDark ? PinTokens.darkEnergyLowBg : PinTokens.energyLowBg;
      textColor = isDark ? PinTokens.darkEnergyLowText : PinTokens.energyLowText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PinTokens.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.energyEmoji,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            task.energyDisplayLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPill(PinTask task, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
        borderRadius: PinTokens.radiusFull,
      ),
      child: Text(
        DateHelpers.formatMinutes(task.estimatedMinutes),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildTrackedPill(PinTask task, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkTimerBg : PinTokens.energyTimerBg,
        borderRadius: PinTokens.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 11,
            color: isDark ? PinTokens.darkTimerText : PinTokens.energyTimerText,
          ),
          const SizedBox(width: 3),
          Text(
            DateHelpers.formatSeconds(task.trackedSeconds),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? PinTokens.darkTimerText : PinTokens.energyTimerText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag, bool isDark) {
    final clean = tag.trim();
    if (clean.contains('\n') || clean.contains(' ')) {
      final subTags = clean
          .split(RegExp(r'[\n\s]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: subTags.map((t) => _buildSingleTag(t, isDark)).toList(),
      );
    }
    return _buildSingleTag(clean, isDark);
  }

  Widget _buildSingleTag(String tag, bool isDark) {
    final clean = tag.startsWith('#') ? tag : '#$tag';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        clean,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildSubtasksPill(PinTask task, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
        borderRadius: PinTokens.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 12,
            color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            '${task.completedSubtasksCount}/${task.totalSubtasksCount}',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
