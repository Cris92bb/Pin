import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/ai_config_service.dart';

/// Segmented selector widget for configuring AI execution mode in Pin.
class ExecutionModeSelector extends StatelessWidget {
  final AiExecutionMode currentMode;
  final ValueChanged<AiExecutionMode> onModeChanged;

  const ExecutionModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, size: 16, color: textPrimary),
            const SizedBox(width: 8),
            Text(
              'Execution Strategy',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildModeOption(
          context: context,
          mode: AiExecutionMode.auto,
          title: 'Auto (Recommended)',
          description:
              'Prioritizes On-Device Gemini Nano if supported; seamlessly falls back to Cloud API key.',
          icon: Icons.auto_mode_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          context: context,
          mode: AiExecutionMode.onDeviceOnly,
          title: 'On-Device Only (Gemini Nano)',
          description:
              '100% private and offline inference. Fails if device or AICore is unsupported.',
          icon: Icons.offline_bolt_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          context: context,
          mode: AiExecutionMode.cloudOnly,
          title: 'Cloud API Only',
          description: 'Always routes requests to Google Gemini via your personal API key.',
          icon: Icons.cloud_queue_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required AiExecutionMode mode,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = currentMode == mode;
    final activeColor = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final borderColor = isSelected
        ? activeColor
        : (isDark ? PinTokens.darkBorder : PinTokens.lightBorder);

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return InkWell(
      onTap: () => onModeChanged(mode),
      borderRadius: PinTokens.radiusCard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: PinTokens.radiusCard,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? activeColor : textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
