import 'package:flutter/material.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/ui/atomic_step_tile.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Atomic micro-steps checklist section for TaskCrudModal.
class TaskCrudSubtasksSection extends StatelessWidget {
  /// Subtasks list.
  final List<AtomicStep> subtasks;

  /// Text controller for entering a new micro step.
  final TextEditingController subtaskController;

  /// Callback when adding a micro step.
  final VoidCallback onAddSubtask;

  /// Callback when toggling completion of a step.
  final void Function(int index, bool isCompleted) onToggleStep;

  /// Callback when deleting a step.
  final ValueChanged<int> onDeleteStep;

  /// Creates a [TaskCrudSubtasksSection].
  const TaskCrudSubtasksSection({
    super.key,
    required this.subtasks,
    required this.subtaskController,
    required this.onAddSubtask,
    required this.onToggleStep,
    required this.onDeleteStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final inputBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg;

    final completedCount = subtasks.where((s) => s.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Atomic Micro-Steps (Sub-15m)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              '$completedCount/${subtasks.length}',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? PinTokens.darkTextMuted
                    : PinTokens.lightTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: subtaskController,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add micro action...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? PinTokens.darkTextMuted
                        : PinTokens.lightTextTertiary,
                    fontSize: 12,
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
                    borderSide: BorderSide(color: borderColor, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: PinTokens.radiusMd,
                    borderSide: BorderSide(color: borderColor, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: PinTokens.radiusMd,
                    borderSide: BorderSide(
                      color: isDark
                          ? PinTokens.darkActiveFocus
                          : PinTokens.lightFabBg,
                      width: 1.2,
                    ),
                  ),
                ),
                onSubmitted: (_) => onAddSubtask(),
              ),
            ),
            const SizedBox(width: 8),
            PinButton(
              icon: Icons.add_rounded,
              text: 'Add',
              isCompact: true,
              onPressed: onAddSubtask,
            ),
          ],
        ),
        if (subtasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            children: subtasks.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return AtomicStepTile(
                step: step,
                isEditable: true,
                onToggle: (val) => onToggleStep(idx, val),
                onDelete: () => onDeleteStep(idx),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
