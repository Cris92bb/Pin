import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Header for TaskCrudModal displaying the mode title and action buttons.
class TaskCrudHeader extends StatelessWidget {
  /// Whether the modal is in edit mode.
  final bool isEditing;

  /// Whether dark mode is active.
  final bool isDark;

  /// Callback when AI settings icon is tapped.
  final VoidCallback onOpenAiSettings;

  /// Optional callback when share button is tapped (editing mode).
  final VoidCallback? onShare;

  /// Callback when close button is tapped.
  final VoidCallback onClose;

  /// Creates a [TaskCrudHeader].
  const TaskCrudHeader({
    super.key,
    required this.isEditing,
    required this.isDark,
    required this.onOpenAiSettings,
    this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isEditing ? 'Edit Pin' : 'Capture New Pin',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing && onShare != null)
              IconButton(
                tooltip: 'Share Pin',
                icon: const Icon(Icons.share_rounded, size: 18),
                color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                splashRadius: 18,
                onPressed: onShare,
              ),
            IconButton(
              tooltip: 'Gemini AI Settings',
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              color: isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
              splashRadius: 18,
              onPressed: onOpenAiSettings,
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark
                    ? PinTokens.darkTextSecondary
                    : PinTokens.lightTextTertiary,
                size: 20,
              ),
              splashRadius: 18,
              onPressed: onClose,
            ),
          ],
        ),
      ],
    );
  }
}
