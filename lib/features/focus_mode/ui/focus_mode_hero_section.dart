import 'package:flutter/material.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../shared/ui/pill_chip.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Hero section for FocusModeView showing task metadata and large timer.
class FocusModeHeroSection extends StatelessWidget {
  /// The task currently focused.
  final PinTask task;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Whether the screen layout is narrow.
  final bool isNarrow;

  /// Total elapsed seconds including prior sessions.
  final int totalElapsedSeconds;

  /// Seconds in current running session.
  final int sessionSeconds;

  /// Whether the session timer is running.
  final bool isRunning;

  /// Callback to toggle pause/resume.
  final VoidCallback onToggleTimer;

  /// Callback to reset session timer.
  final VoidCallback onResetTimer;

  /// Creates a [FocusModeHeroSection].
  const FocusModeHeroSection({
    super.key,
    required this.task,
    required this.isDark,
    required this.isNarrow,
    required this.totalElapsedSeconds,
    required this.sessionSeconds,
    required this.isRunning,
    required this.onToggleTimer,
    required this.onResetTimer,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final textMuted =
        isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? PinTokens.space16 : PinTokens.space24,
        PinTokens.space16,
        isNarrow ? PinTokens.space16 : PinTokens.space24,
        PinTokens.space16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          children: [
            // Meta Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PillChip.energy(
                  tag: task.energyTag,
                  isCompact: true,
                ),
                const SizedBox(width: 8),
                PillChip.duration(
                  durationText: DateHelpers.formatMinutes(task.estimatedMinutes),
                  isCompact: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task Title
            Text(
              task.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.5,
                height: 1.25,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Big Stopwatch Display
            Column(
              children: [
                Text(
                  DateHelpers.formatSeconds(totalElapsedSeconds),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: textPrimary,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRunning
                      ? 'Session Live • +${DateHelpers.formatSeconds(sessionSeconds)}'
                      : 'Session Paused',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isRunning
                        ? (isDark
                            ? PinTokens.accentEmerald
                            : PinTokens.lightFabBg)
                        : textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    PinButton(
                      icon: isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      text: isRunning ? 'Pause' : 'Resume',
                      variant: isRunning
                          ? PinButtonVariant.secondary
                          : PinButtonVariant.primary,
                      width: 120,
                      onPressed: onToggleTimer,
                    ),
                    PinButton(
                      icon: Icons.refresh_rounded,
                      text: 'Reset',
                      variant: PinButtonVariant.secondary,
                      width: 120,
                      onPressed: onResetTimer,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
