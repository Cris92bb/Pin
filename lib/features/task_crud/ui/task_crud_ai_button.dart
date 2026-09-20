import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Button offering Gemini AI prompt analysis and auto-fill breakdown.
class TaskCrudAiButton extends StatelessWidget {
  /// Whether an AI breakdown generation is in flight.
  final bool isGeneratingWithAi;

  /// Whether the modal is currently in edit mode (vs create mode).
  final bool isEditing;

  /// Whether dark mode is active.
  final bool isDark;

  /// Callback to trigger the AI generation.
  final VoidCallback onTap;

  /// Creates a [TaskCrudAiButton].
  const TaskCrudAiButton({
    super.key,
    required this.isGeneratingWithAi,
    required this.isEditing,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: PinTokens.radiusMd,
        onTap: isGeneratingWithAi ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: PinTokens.radiusMd,
            color: isDark ? PinTokens.darkInputBg : PinTokens.lightTagBg,
            border: Border.all(
              color: isDark ? PinTokens.darkInputBorder : PinTokens.lightBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGeneratingWithAi) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Decomposing task with Gemini...',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? PinTokens.accentEmerald
                          : PinTokens.lightFabBg,
                    ),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color:
                      isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isEditing
                        ? 'Re-analyze & break down with Gemini'
                        : 'Break down & auto-fill with Gemini',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? PinTokens.accentEmerald
                          : PinTokens.lightFabBg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
