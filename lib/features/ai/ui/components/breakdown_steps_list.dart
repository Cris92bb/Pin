import 'package:flutter/material.dart';
import '../../../../entities/task/model/atomic_step.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Modular sub-component for viewing, adding, and removing atomic subtasks
/// within the AI task breakdown preview.
class BreakdownStepsList extends StatelessWidget {
  final List<AtomicStep> steps;
  final TextEditingController newStepController;
  final VoidCallback onAddStep;
  final ValueChanged<int> onRemoveStep;

  const BreakdownStepsList({
    super.key,
    required this.steps,
    required this.newStepController,
    required this.onAddStep,
    required this.onRemoveStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final activeFocus = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Atomic Subtasks (${steps.length})',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isDark ? PinTokens.darkEnergyLowText : PinTokens.energyLowAccentText)
                    .withValues(alpha: 0.15),
                borderRadius: PinTokens.radiusFull,
              ),
              child: Text(
                'each ≤ 15 min',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PinTokens.darkEnergyLowText : PinTokens.energyLowAccentText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: activeFocus.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: activeFocus,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i].title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
                    borderRadius: PinTokens.radiusFull,
                  ),
                  child: Text(
                    '${steps[i].estimatedMinutes}m',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  splashRadius: 16,
                  onPressed: () => onRemoveStep(i),
                  tooltip: 'Remove step',
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: newStepController,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add an atomic subtask...',
                    hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg,
                    border: OutlineInputBorder(
                      borderRadius: PinTokens.radiusMd,
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: PinTokens.radiusMd,
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: PinTokens.radiusMd,
                      borderSide: BorderSide(color: activeFocus, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => onAddStep(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAddStep,
              icon: const Icon(Icons.add_rounded),
              color: activeFocus,
              tooltip: 'Add subtask',
            ),
          ],
        ),
      ],
    );
  }
}
