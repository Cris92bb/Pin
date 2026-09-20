import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Form text fields for Pin title and description in TaskCrudModal.
class TaskCrudFormFields extends StatelessWidget {
  /// Controller for title input.
  final TextEditingController titleController;

  /// Controller for description input.
  final TextEditingController descController;

  /// Optional inline error message.
  final String? inlineError;

  /// Callback when title is submitted via keyboard.
  final VoidCallback onSubmit;

  /// Widget placed between title and description (e.g. AI breakdown button).
  final Widget? middleWidget;

  /// Creates a [TaskCrudFormFields].
  const TaskCrudFormFields({
    super.key,
    required this.titleController,
    required this.descController,
    this.inlineError,
    required this.onSubmit,
    this.middleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final inputBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCanvasBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inlineError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PinTokens.accentAmber.withValues(alpha: 0.12),
              borderRadius: PinTokens.radiusMd,
              border: Border.all(
                color: PinTokens.accentAmber.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: PinTokens.accentAmber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inlineError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PinTokens.accentAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: titleController,
          autofocus: true,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'What needs execution?',
            hintStyle: TextStyle(
              color: isDark
                  ? PinTokens.darkTextMuted
                  : PinTokens.lightTextTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(
                color: isDark
                    ? PinTokens.darkActiveFocus
                    : PinTokens.lightFabBg,
                width: 1.2,
              ),
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        if (middleWidget != null) ...[
          const SizedBox(height: 8),
          middleWidget!,
        ],
        const SizedBox(height: 12),
        TextField(
          controller: descController,
          maxLines: 2,
          style: TextStyle(fontSize: 13, color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Optional notes, blockers, or context...',
            hintStyle: TextStyle(
              color: isDark
                  ? PinTokens.darkTextMuted
                  : PinTokens.lightTextTertiary,
              fontSize: 13,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(
                color: isDark
                    ? PinTokens.darkActiveFocus
                    : PinTokens.lightFabBg,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
