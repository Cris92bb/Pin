import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/ui/atomic_step_tile.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Interactive subtasks section within FocusModeView.
class FocusModeSubtasksSection extends StatelessWidget {
  /// The task currently focused.
  final PinTask task;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Whether the screen is narrow.
  final bool isNarrow;

  /// Parent constraints for calculating minimum height.
  final BoxConstraints constraints;

  /// Controller for the micro-step text field.
  final TextEditingController stepController;

  /// Callback when a step checkbox is toggled.
  final void Function(int index, bool checked) onToggleStep;

  /// Callback when a step is deleted.
  final void Function(int index) onDeleteStep;

  /// Callback when adding a new step.
  final VoidCallback onAddNewStep;

  /// Creates a [FocusModeSubtasksSection].
  const FocusModeSubtasksSection({
    super.key,
    required this.task,
    required this.isDark,
    required this.isNarrow,
    required this.constraints,
    required this.stepController,
    required this.onToggleStep,
    required this.onDeleteStep,
    required this.onAddNewStep,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = task.totalSubtasksCount;
    final completedSteps = task.completedSubtasksCount;
    final progress = task.subtaskProgress;

    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final textMuted =
        isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted;
    final borderDefault =
        isDark ? PinTokens.borderDefault : PinTokens.lightBorder;

    final subtasksBg =
        isDark ? PinTokens.darkSurfaceCardMuted : PinTokens.lightSheetBg;
    final inputBg =
        isDark ? PinTokens.surfaceCard : PinTokens.lightCardBg;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: constraints.maxHeight - 100 > 240
            ? constraints.maxHeight - 100
            : 240,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? PinTokens.space16 : PinTokens.space24,
          vertical: PinTokens.space20,
        ),
        decoration: BoxDecoration(
          color: subtasksBg,
          borderRadius: const BorderRadius.all(
            Radius.circular(24),
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Atomic Subtasks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    if (totalSteps > 0)
                      Text(
                        '$completedSteps / $totalSteps completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: completedSteps == totalSteps
                              ? (isDark
                                  ? PinTokens.accentEmerald
                                  : PinTokens.lightFabBg)
                              : textMuted,
                        ),
                      ),
                  ],
                ),
                if (totalSteps > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: PinTokens.radiusFull,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? PinTokens.canvasBg
                          : PinTokens.lightBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Subtasks list
                if (task.subtasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'No subtasks yet. Break this task into bite-sized steps below.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: task.subtasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final step = task.subtasks[index];
                      return AtomicStepTile(
                        step: step,
                        isEditable: true,
                        onToggle: (checked) => onToggleStep(index, checked),
                        onDelete: () => onDeleteStep(index),
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // Quick add step
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stepController,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add micro-step (<= 15m)...',
                          hintStyle: TextStyle(
                            color: textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(
                              color: borderDefault,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(
                              color: borderDefault,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: PinTokens.radiusMd,
                            borderSide: BorderSide(
                              color: isDark
                                  ? PinTokens.accentEmerald
                                  : PinTokens.lightFabBg,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => onAddNewStep(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PinButton(
                      icon: Icons.add_rounded,
                      text: 'Add',
                      isCompact: true,
                      onPressed: onAddNewStep,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
