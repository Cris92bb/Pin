import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Metadata pills row for [TaskCard] displaying energy, duration, timer, tags, and subtasks.
///
/// Architecture & Role:
/// - Layer: `widgets/kanban_board/components` (Feature-Sliced Design v2.1)
/// - Single responsibility: Render task metadata pills and hashtag chips with strict design tokens.
class TaskCardMetadataRow extends StatelessWidget {
  /// The task whose metadata is displayed.
  final PinTask task;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [TaskCardMetadataRow].
  const TaskCardMetadataRow({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Energy Pill
        _buildEnergyPill(task, isDark),

        // Duration Pill
        _buildDurationPill(task, isDark),

        // Tracked time counter (if any)
        if (task.trackedSeconds > 0) _buildTrackedPill(task, isDark),

        // Hashtag chips
        for (final tag in task.tags) _buildTagChip(tag, isDark),

        // Subtasks indicator
        if (task.hasSubtasks) _buildSubtasksPill(task, isDark),
      ],
    );
  }

  Widget _buildEnergyPill(PinTask task, bool isDark) {
    Color bg;
    Color textColor;

    final lower = task.energyTag.toLowerCase();
    if (lower.contains('deep') || lower.contains('focus')) {
      bg = isDark ? PinTokens.darkEnergyFocusBg : PinTokens.energyDeepBg;
      textColor =
          isDark ? PinTokens.darkEnergyFocusText : PinTokens.energyDeepText;
    } else if (lower.contains('medium') || lower.contains('flow')) {
      bg = isDark ? PinTokens.darkEnergyMediumBg : PinTokens.energyMediumBg;
      textColor =
          isDark ? PinTokens.darkEnergyMediumText : PinTokens.energyMediumText;
    } else if (lower.contains('creative')) {
      bg = isDark ? PinTokens.darkEnergyCreativeBg : PinTokens.energyCreativeBg;
      textColor = isDark
          ? PinTokens.darkEnergyCreativeText
          : PinTokens.energyCreativeText;
    } else if (lower.contains('admin')) {
      bg = isDark ? PinTokens.darkEnergyAdminBg : PinTokens.energyAdminBg;
      textColor =
          isDark ? PinTokens.darkEnergyAdminText : PinTokens.energyAdminText;
    } else {
      bg = isDark ? PinTokens.darkEnergyLowBg : PinTokens.energyLowBg;
      textColor =
          isDark ? PinTokens.darkEnergyLowText : PinTokens.energyLowText;
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
          color: isDark
              ? PinTokens.darkTextSecondary
              : PinTokens.lightTextSecondary,
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
            color: isDark
                ? PinTokens.darkTimerText
                : PinTokens.energyTimerText,
          ),
          const SizedBox(width: 3),
          Text(
            DateHelpers.formatSeconds(task.trackedSeconds),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? PinTokens.darkTimerText
                  : PinTokens.energyTimerText,
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
          color: isDark
              ? PinTokens.darkTextSecondary
              : PinTokens.lightTextSecondary,
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
            color: isDark
                ? PinTokens.darkTextSecondary
                : PinTokens.lightTextSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            '${task.completedSubtasksCount}/${task.totalSubtasksCount}',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? PinTokens.darkTextSecondary
                  : PinTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
