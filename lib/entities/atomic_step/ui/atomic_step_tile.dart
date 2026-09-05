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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: step.isCompleted
            ? PinTokens.canvasBg.withValues(alpha: 0.3)
            : PinTokens.surfaceCard.withValues(alpha: 0.5),
        borderRadius: PinTokens.radiusMd,
        border: Border.all(
          color: step.isCompleted
              ? PinTokens.borderSubtle
              : PinTokens.borderDefault.withValues(alpha: 0.5),
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
                      : PinTokens.textMuted,
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
                    ? PinTokens.textMuted
                    : PinTokens.textPrimary,
                decoration:
                    step.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: PinTokens.textMuted,
              ),
            ),
          ),

          // Sub-15m duration badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: PinTokens.canvasBg,
              borderRadius: PinTokens.radiusFull,
              border: Border.all(color: PinTokens.borderSubtle, width: 1),
            ),
            child: Text(
              '${step.estimatedMinutes}m',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: PinTokens.textSecondary,
              ),
            ),
          ),

          // Optional delete action
          if (isEditable && onDelete != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onDelete,
              borderRadius: PinTokens.radiusSm,
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: PinTokens.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
