import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Pill badge showing which AI engine executed the task breakdown.
class BreakdownEngineBadge extends StatelessWidget {
  final bool isLocalOnDevice;
  final String? engineName;
  final Duration? duration;

  const BreakdownEngineBadge({
    super.key,
    required this.isLocalOnDevice,
    this.engineName,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color badgeBg;
    final Color badgeFg;
    final IconData icon;
    final String label;

    if (isLocalOnDevice) {
      badgeBg = isDark ? PinTokens.darkEnergyLowBg : PinTokens.lightSheetBg;
      badgeFg = isDark ? PinTokens.darkEnergyLowText : PinTokens.lightActiveFocus;
      icon = Icons.bolt_rounded;
      label = engineName ?? 'On-Device Gemini Nano';
    } else {
      badgeBg = isDark ? PinTokens.darkEnergyFocusBg : PinTokens.lightTagBg;
      badgeFg = isDark ? PinTokens.darkEnergyFocusText : PinTokens.lightTextPrimary;
      icon = Icons.cloud_outlined;
      label = engineName ?? 'Cloud Gemini';
    }

    final durationText = duration != null ? ' (${duration!.inMilliseconds}ms)' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeFg.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeFg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label$durationText',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: badgeFg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
