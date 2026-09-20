import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Preview and selection list for decoded blueprint tasks.
///
/// Displays the decoded task items with individual selection checkboxes
/// and a bulk toggle action, matching Pin's tactile theme tokens.
class ImportBlueprintTaskList extends StatelessWidget {
  /// Raw list of task maps decoded from blueprint.
  final List<Map<String, dynamic>> tasks;

  /// Set of indices that are currently selected for import.
  final Set<int> selectedIndices;

  /// Callback triggered when an individual task's checkbox is toggled.
  final void Function(int index, bool selected) onToggleIndex;

  /// Callback triggered when toggling all items between selected and deselected.
  final VoidCallback onToggleAll;

  const ImportBlueprintTaskList({
    super.key,
    required this.tasks,
    required this.selectedIndices,
    required this.onToggleIndex,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkCanvasBg : PinTokens.surfaceColumn,
        borderRadius: PinTokens.radiusMd,
        border: Border.all(
          color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
        ),
      ),
      child: tasks.isEmpty
          ? Center(
              child: Text(
                'Paste a blueprint code above to preview tasks.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Decoded ${tasks.length} tasks (Selected: ${selectedIndices.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PinTokens.accentEmerald,
                      ),
                    ),
                    InkWell(
                      onTap: onToggleAll,
                      child: Text(
                        selectedIndices.length == tasks.length ? 'Deselect All' : 'Select All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final isChecked = selectedIndices.contains(index);
                      return CheckboxListTile(
                        dense: true,
                        value: isChecked,
                        activeColor: isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus,
                        title: Text(
                          task['title'] ?? 'Untitled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${task['status'] ?? 'backlog'} • ${task['estimatedMinutes'] ?? 15}m',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        onChanged: (val) => onToggleIndex(index, val == true),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
