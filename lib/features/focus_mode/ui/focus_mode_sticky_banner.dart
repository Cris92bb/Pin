import 'package:flutter/material.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Minimized sticky timer banner that slides into view when scrolling past hero timer.
class FocusModeStickyBanner extends StatelessWidget {
  /// Whether the dark theme is active.
  final bool isDark;

  /// Total elapsed seconds including previous sessions.
  final int totalElapsedSeconds;

  /// Whether the session stopwatch is currently running.
  final bool isRunning;

  /// Callback to toggle pause/resume on the timer.
  final VoidCallback onToggleTimer;

  /// Callback to reset current session seconds.
  final VoidCallback onResetTimer;

  /// Creates a [FocusModeStickyBanner].
  const FocusModeStickyBanner({
    super.key,
    required this.isDark,
    required this.totalElapsedSeconds,
    required this.isRunning,
    required this.onToggleTimer,
    required this.onResetTimer,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textMuted =
        isDark ? PinTokens.darkTextMuted : PinTokens.lightTextMuted;
    final borderSubtle =
        isDark ? PinTokens.darkBorderSubtle : PinTokens.lightBorder;
    final bannerBg =
        isDark ? PinTokens.surfaceColumn : PinTokens.lightSheetBg;

    return Container(
      key: const ValueKey('sticky_timer_banner'),
      padding: const EdgeInsets.symmetric(
        horizontal: PinTokens.space16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(color: borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning
                  ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                  : textMuted,
            ),
          ),
          const SizedBox(width: 8),

          // Compact Timer Digits
          Text(
            DateHelpers.formatSeconds(totalElapsedSeconds),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),

          // Status text
          Text(
            isRunning ? 'Live' : 'Paused',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isRunning
                  ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                  : textMuted,
            ),
          ),

          const Spacer(),

          // Compact action buttons
          PinButton(
            icon: isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            text: isRunning ? 'Pause' : 'Resume',
            variant: isRunning
                ? PinButtonVariant.secondary
                : PinButtonVariant.primary,
            isCompact: true,
            onPressed: onToggleTimer,
          ),
          const SizedBox(width: 8),
          PinButton(
            icon: Icons.refresh_rounded,
            text: 'Reset',
            variant: PinButtonVariant.secondary,
            isCompact: true,
            onPressed: onResetTimer,
          ),
        ],
      ),
    );
  }
}
