import 'package:flutter/material.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import 'package:pin/shared/ui/pin_tokens.dart';

/// Card previewing the AI-refined task objective, energy level,
/// estimated duration, and associated tags.
class RefinedObjectiveCard extends StatelessWidget {
  /// Refined task title.
  final String title;

  /// Refined task description.
  final String description;

  /// Energy classification tag (e.g., 'deep-focus', 'quick-win').
  final String energyTag;

  /// Total estimated duration in minutes.
  final int estimatedMinutes;

  /// Tags associated with the task breakdown.
  final List<String> tags;

  const RefinedObjectiveCard({
    super.key,
    required this.title,
    required this.description,
    required this.energyTag,
    required this.estimatedMinutes,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
    final activeFocus = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final cardBg = isDark ? PinTokens.darkSheetBg : PinTokens.lightCanvasBg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFINED OBJECTIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: activeFocus,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12.5, color: textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(
                '⚡ ${energyTag.toUpperCase()}',
                isDark ? PinTokens.darkEnergyLowBg : PinTokens.lightTagBg,
                textPrimary,
              ),
              _chip(
                DateHelpers.formatMinutes(estimatedMinutes),
                isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
                textSecondary,
              ),
              for (final tag in tags)
                _chip(
                  tag.startsWith('#') ? tag : '#$tag',
                  isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
                  textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PinTokens.radiusFull,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
