import 'package:flutter/material.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Timer display container for the wearable focus mode.
class WearableFocusTimerCard extends StatelessWidget {
  /// Total formatted timer string (mm:ss).
  final String formattedTime;

  /// Whether the session timer is currently ticking.
  final bool isRunning;

  /// Creates a [WearableFocusTimerCard].
  const WearableFocusTimerCard({
    super.key,
    required this.formattedTime,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: PinTokens.wearableCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRunning
                ? PinTokens.accentEmerald.withValues(alpha: 0.6)
                : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Text(
          formattedTime,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Circular action controls for pausing/resuming timer and completing task in focus mode.
class WearableFocusActionButtons extends StatelessWidget {
  /// Whether the session timer is currently active.
  final bool isRunning;

  /// Callback to toggle pause/play state.
  final VoidCallback onToggleTimer;

  /// Callback to finish and complete the task.
  final VoidCallback onCompleteTask;

  /// Creates a [WearableFocusActionButtons] row.
  const WearableFocusActionButtons({
    super.key,
    required this.isRunning,
    required this.onToggleTimer,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onToggleTimer,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRunning
                  ? Colors.amber.withValues(alpha: 0.2)
                  : PinTokens.accentEmerald.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isRunning ? Colors.amber : PinTokens.accentEmerald,
                width: 1.5,
              ),
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: isRunning ? Colors.amber : PinTokens.accentEmerald,
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onCompleteTask,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PinTokens.accentEmerald.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: PinTokens.accentEmerald,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 22,
              color: PinTokens.accentEmerald,
            ),
          ),
        ),
      ],
    );
  }
}

/// Interactive step tile within the wearable focus mode subtask checklist.
class WearableFocusStepTile extends StatelessWidget {
  /// The atomic subtask to render.
  final AtomicStep step;

  /// Callback invoked when toggling completion.
  final ValueChanged<bool> onToggle;

  /// Creates a [WearableFocusStepTile] for [step].
  const WearableFocusStepTile({
    super.key,
    required this.step,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onToggle(!step.isCompleted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: PinTokens.wearableStepBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              step.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 16,
              color: step.isCompleted
                  ? PinTokens.accentEmerald
                  : Colors.white38,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  color: step.isCompleted ? Colors.white38 : Colors.white,
                  fontSize: 11,
                  decoration:
                      step.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
