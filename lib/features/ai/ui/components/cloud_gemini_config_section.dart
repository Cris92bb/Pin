import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Configuration sub-section for Cloud Gemini API settings, including
/// API key entry with visibility toggle, AI Studio link, and model selection.
class CloudGeminiConfigSection extends StatelessWidget {
  /// Controller for the Gemini API key input field.
  final TextEditingController controller;

  /// Whether the API key is obscured in the text field.
  final bool obscureKey;

  /// Callback when the visibility toggle button is pressed.
  final VoidCallback onToggleObscure;

  /// Currently selected Gemini cloud model.
  final String selectedModel;

  /// List of available Gemini cloud models.
  final List<String> availableModels;

  /// Callback when a different Gemini model is selected.
  final ValueChanged<String> onModelChanged;

  const CloudGeminiConfigSection({
    super.key,
    required this.controller,
    required this.obscureKey,
    required this.onToggleObscure,
    required this.selectedModel,
    required this.availableModels,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final surfaceBg = isDark ? Colors.white.withValues(alpha: 0.04) : PinTokens.lightCanvasBg;
    final activeFocus = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GEMINI API KEY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
            Text(
              'aistudio.google.com',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: activeFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureKey,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'AIzaSy... (optional if On-Device Nano is ready)',
            hintStyle: TextStyle(
              fontSize: 12,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: surfaceBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(
                color: activeFocus,
                width: 1.2,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureKey ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cloud Model',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            DropdownButton<String>(
              value: selectedModel,
              dropdownColor: isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg,
              style: TextStyle(fontSize: 12.5, color: textPrimary),
              items: availableModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => v != null ? onModelChanged(v) : null,
            ),
          ],
        ),
      ],
    );
  }
}
