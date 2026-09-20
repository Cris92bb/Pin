import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Lightweight compact card used in inactive Kanban drawers.
///
/// Designed for read-only preview of pins in dormant drawers without interactive
/// buttons or deep gesture handlers.
class WideFoldCompactCard extends StatelessWidget {
  /// The task to display.
  final PinTask task;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldCompactCard].
  const WideFoldCompactCard({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    // Primary tag color pip
    Color? tagPipColor;
    if (task.tags.isNotEmpty) {
      final firstTag = task.tags.first.toLowerCase().trim();
      if (firstTag.contains('dev') || firstTag.contains('code')) {
        tagPipColor =
            isDark ? PinTokens.darkActiveFocus : PinTokens.accentViolet;
      } else if (firstTag.contains('design') || firstTag.contains('ui')) {
        tagPipColor = PinTokens.accentSky;
      } else if (firstTag.contains('bug') || firstTag.contains('fix')) {
        tagPipColor = PinTokens.accentRose;
      } else if (firstTag.contains('doc') || firstTag.contains('write')) {
        tagPipColor = PinTokens.accentAmber;
      } else {
        tagPipColor = PinTokens.accentEmerald;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusCard,
        border: isDark ? Border.all(color: borderColor, width: 1.0) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: PinTokens.shadowForest.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title — 2 lines max, no interactive controls
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDone
                  ? (isDark
                      ? PinTokens.darkTextSecondary
                      : PinTokens.lightTextTertiary)
                  : textPrimary,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor:
                  isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // Minimal metadata: energy pip + tag pip
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Energy label as small text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
                  borderRadius: PinTokens.radiusFull,
                ),
                child: Text(
                  task.energyDisplayLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
              // Duration
              Text(
                DateHelpers.formatMinutes(task.estimatedMinutes),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              // Tag pip (colored dot for the first tag category)
              if (tagPipColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tagPipColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
