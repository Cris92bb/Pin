import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../model/atomic_step.dart';

/// Minimal, interactive checklist tile for bite-sized atomic steps.
class AtomicStepTile extends StatelessWidget {
  final AtomicStep step;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;
  final bool isEditable;

  const AtomicStepTile({
    super.key,
    required this.step,
    this.onToggle,
    this.onDelete,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tileBg = step.isCompleted
        ? (isDark
            ? PinTokens.canvasBg.withValues(alpha: 0.3)
            : const Color(0xFFF3F4F6).withValues(alpha: 0.6))
        : (isDark
            ? PinTokens.surfaceCard.withValues(alpha: 0.5)
            : Colors.white);

    final borderColor = step.isCompleted
        ? (isDark ? PinTokens.borderSubtle : PinTokens.lightBorderSubtle)
        : (isDark
            ? PinTokens.borderDefault.withValues(alpha: 0.5)
            : PinTokens.lightBorderSubtle);

    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final textMuted =
        isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted;

    final badgeBg = isDark ? PinTokens.canvasBg : const Color(0xFFF3F4F6);
    final badgeBorder =
        isDark ? PinTokens.borderSubtle : PinTokens.lightBorderSubtle;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Checkbox toggle
          InkWell(
            onTap: onToggle != null
                ? () => onToggle!(!step.isCompleted)
                : null,
            borderRadius: PinTokens.radiusSm,
            child: AnimatedContainer(
              duration: PinTokens.animFast,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? PinTokens.accentEmerald
                    : Colors.transparent,
                borderRadius: PinTokens.radiusSm,
                border: Border.all(
                  color: step.isCompleted
                      ? PinTokens.accentEmerald
                      : textMuted,
                  width: 1.5,
                ),
              ),
              child: step.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: PinTokens.textInverse,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Title with strikethrough when completed
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: step.isCompleted
                    ? textMuted
                    : textPrimary,
                decoration:
                    step.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: textMuted,
              ),
            ),
          ),

          // Sub-15m duration badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: PinTokens.radiusFull,
              border: Border.all(color: badgeBorder, width: 1),
            ),
            child: Text(
              '${step.estimatedMinutes}m',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),

          // Optional delete action
          if (isEditable && onDelete != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onDelete,
              borderRadius: PinTokens.radiusSm,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
