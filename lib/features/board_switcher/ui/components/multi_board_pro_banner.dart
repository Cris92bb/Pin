import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/board/state/board_providers.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Tactile banner card presenting the Multi-Board Workspaces feature toggle (Pro tier capability).
class MultiBoardProBanner extends ConsumerWidget {
  const MultiBoardProBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final border = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final accent = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;

    final isEnabled = boardState.isMultiBoardEnabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusCard,
        border: Border.all(
          color: isEnabled ? accent.withValues(alpha: 0.5) : border,
          width: isEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEnabled
                  ? accent.withValues(alpha: 0.15)
                  : (isDark ? PinTokens.darkTagBg : PinTokens.lightTagBg),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: isEnabled ? accent : textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Multi-Board Workspaces',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? accent.withValues(alpha: 0.2)
                            : (isDark ? PinTokens.darkTagBg : PinTokens.lightTagBg),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isEnabled ? accent : textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled
                      ? 'Multiple boards enabled. Create separate project workspaces.'
                      : 'Feature toggle: Enable to create additional boards.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: isEnabled,
            activeTrackColor: accent.withValues(alpha: 0.5),
            activeThumbColor: accent,
            onChanged: (val) {
              ref.read(boardStateProvider.notifier).setMultiBoardEnabled(val);
            },
          ),
        ],
      ),
    );
  }
}
