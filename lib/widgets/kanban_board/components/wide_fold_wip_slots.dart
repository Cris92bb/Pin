import 'package:flutter/material.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';

/// WIP slots indicator dots for Today status drawers.
class WideFoldWipSlots extends StatelessWidget {
  /// The global task state containing WIP limit and today tasks.
  final TaskListState state;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldWipSlots] widget.
  const WideFoldWipSlots({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(state.wipLimit, (index) {
        final isFilled = index < state.todayTasks.length;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (isDark
                    ? PinTokens.darkActiveFocus
                    : PinTokens.lightActiveFocus)
                : (isDark
                    ? PinTokens.darkBorder
                    : PinTokens.lightBorder),
          ),
        );
      }),
    );
  }
}
