import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Loading state view for the AI task breakdown process.
class BreakdownLoadingView extends StatelessWidget {
  final String taskTitle;

  const BreakdownLoadingView({
    super.key,
    required this.taskTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final activeColor = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Analyzing "$taskTitle"...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Decomposing into atomic subtasks (≤ 15 mins) and refining focus properties...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Error display view with action button to open AI settings and retry.
class BreakdownErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onOpenSettings;

  const BreakdownErrorView({
    super.key,
    required this.errorMessage,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dangerColor = isDark ? PinTokens.dangerFgDark : PinTokens.dangerFgLight;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dangerColor.withValues(alpha: 0.1),
          borderRadius: PinTokens.radiusMd,
          border: Border.all(color: dangerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: dangerColor, size: 28),
            const SizedBox(height: 8),
            Text(
              'Failed to analyze task',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: dangerColor),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: dangerColor),
            ),
            const SizedBox(height: 12),
            PinButton(
              icon: Icons.settings_rounded,
              text: 'AI Settings',
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}
