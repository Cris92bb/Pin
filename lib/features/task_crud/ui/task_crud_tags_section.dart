import 'package:flutter/material.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Tags management section for TaskCrudModal.
class TaskCrudTagsSection extends StatelessWidget {
  /// Currently assigned tags list.
  final List<String> tags;

  /// Quick tag suggestions.
  final List<String> quickTags;

  /// Standard quick tags palette.
  static const List<String> defaultQuickTags = [
    '#dev',
    '#ui',
    '#admin',
    '#quick-win',
    '#design',
    '#docs',
  ];

  /// Controller for entering a new custom tag.
  final TextEditingController tagController;

  /// Callback to add a tag.
  final ValueChanged<String> onAddTag;

  /// Callback to remove a tag.
  final ValueChanged<String> onRemoveTag;

  /// Creates a [TaskCrudTagsSection].
  const TaskCrudTagsSection({
    super.key,
    required this.tags,
    this.quickTags = defaultQuickTags,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in tags)
              Chip(
                label: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? PinTokens.darkTextPrimary
                        : PinTokens.lightTextPrimary,
                  ),
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isDark ? PinTokens.darkBorder : PinTokens.lightBorder,
                    width: 1.0,
                  ),
                ),
                backgroundColor:
                    isDark ? PinTokens.darkCardBg : PinTokens.lightSheetBg,
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: isDark
                      ? PinTokens.darkTextMuted
                      : PinTokens.lightTextTertiary,
                ),
                onDeleted: () => onRemoveTag(tag),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            for (final qTag in quickTags)
              if (!tags.contains(qTag))
                ActionChip(
                  label: Text(
                    qTag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? PinTokens.darkTextSecondary
                          : PinTokens.lightTextSecondary,
                    ),
                  ),
                  shape: const StadiumBorder(
                    side: BorderSide(
                      color: PinTokens.lightBorder,
                      width: 1.0,
                    ),
                  ),
                  backgroundColor:
                      isDark ? PinTokens.darkCardBg : PinTokens.lightTagBg,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => onAddTag(qTag),
                ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: tagController,
                style: TextStyle(fontSize: 11, color: textPrimary),
                decoration: InputDecoration(
                  hintText: '+ tag',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? PinTokens.darkTextMuted
                        : PinTokens.lightTextTertiary,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  filled: true,
                  fillColor:
                      isDark ? PinTokens.darkCardBg : PinTokens.lightTagBg,
                  border: OutlineInputBorder(
                    borderRadius: PinTokens.radiusFull,
                    borderSide: BorderSide(color: borderColor, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: PinTokens.radiusFull,
                    borderSide: BorderSide(color: borderColor, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: PinTokens.radiusFull,
                    borderSide: BorderSide(
                      color: isDark
                          ? PinTokens.darkActiveFocus
                          : PinTokens.lightFabBg,
                      width: 1.2,
                    ),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    onAddTag(val.trim());
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
