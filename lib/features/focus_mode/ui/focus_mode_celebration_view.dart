import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Celebration view displayed upon completing a task in Focus Mode.
class FocusModeCelebrationView extends StatelessWidget {
  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [FocusModeCelebrationView].
  const FocusModeCelebrationView({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PinTokens.accentEmerald.withValues(alpha: 0.15),
              border: Border.all(color: PinTokens.accentEmerald, width: 2),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 56,
              color: PinTokens.accentEmerald,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Task Completed!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? PinTokens.darkTextPrimary
                  : PinTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great execution momentum. Returning to board...',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? PinTokens.darkTextSecondary
                  : PinTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
