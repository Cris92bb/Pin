import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Feedback banner showing connection success or error message.
class AiSettingsFeedbackBanner extends StatelessWidget {
  final String? successMessage;
  final String? errorMessage;

  const AiSettingsFeedbackBanner({
    super.key,
    this.successMessage,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuccess = successMessage != null;
    final color = isSuccess
        ? (isDark ? PinTokens.darkEnergyLowText : PinTokens.energyLowAccentText)
        : (isDark ? PinTokens.dangerFgDark : PinTokens.dangerFgLight);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PinTokens.radiusSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              successMessage ?? errorMessage ?? '',
              style: TextStyle(fontSize: 11.5, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
