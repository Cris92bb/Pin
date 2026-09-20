import 'package:flutter/material.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Top minimal action bar for FocusModeView.
class FocusModeTopBar extends StatelessWidget {
  /// Whether the dark theme is active.
  final bool isDark;

  /// Whether the screen width is narrow (< 780px).
  final bool isNarrow;

  /// Whether the screen width is very narrow (< 360px).
  final bool isVeryNarrow;

  /// Callback to exit focus mode.
  final VoidCallback onExit;

  /// Callback to reanalyze task with AI.
  final VoidCallback onReanalyzeWithAi;

  /// Callback to edit the task in modal.
  final VoidCallback onEditTask;

  /// Callback to mark task complete.
  final VoidCallback onCompleteTask;

  /// Creates a [FocusModeTopBar].
  const FocusModeTopBar({
    super.key,
    required this.isDark,
    required this.isNarrow,
    required this.isVeryNarrow,
    required this.onExit,
    required this.onReanalyzeWithAi,
    required this.onEditTask,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final borderSubtle =
        isDark ? PinTokens.darkBorderSubtle : PinTokens.lightBorder;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? PinTokens.space12 : PinTokens.space24,
        vertical: PinTokens.space12,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderSubtle)),
      ),
      child: Row(
        children: [
          PinButton(
            icon: Icons.arrow_back_rounded,
            text: isNarrow ? (isVeryNarrow ? null : 'Back') : 'Back',
            isCompact: true,
            tooltip: 'Return to Board (Esc)',
            onPressed: onExit,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? PinTokens.accentEmerald.withValues(alpha: 0.15)
                  : PinTokens.lightTagBg,
              borderRadius: PinTokens.radiusFull,
              border: Border.all(
                color: isDark
                    ? PinTokens.accentEmerald.withValues(alpha: 0.5)
                    : PinTokens.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? PinTokens.accentEmerald
                        : PinTokens.lightFabBg,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isNarrow ? 'FOCUS' : 'SINGLE-TASK IMMERSION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? PinTokens.accentEmerald
                        : PinTokens.lightTextPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!isNarrow) ...[
            PinButton(
              icon: Icons.auto_awesome_rounded,
              text: 'AI Breakdown',
              isCompact: true,
              tooltip: 'AI Breakdown & Re-analyze',
              onPressed: onReanalyzeWithAi,
            ),
            const SizedBox(width: 8),
          ],
          if (!isVeryNarrow) ...[
            PinButton(
              icon: Icons.edit_outlined,
              text: isNarrow ? null : 'Edit',
              isCompact: true,
              tooltip: 'Edit Pin',
              onPressed: onEditTask,
            ),
            const SizedBox(width: 8),
          ],
          PinButton.primary(
            icon: Icons.check_circle_outline_rounded,
            text: isNarrow ? (isVeryNarrow ? null : 'Done') : 'Done & Exit',
            isCompact: true,
            onPressed: onCompleteTask,
          ),
        ],
      ),
    );
  }
}
