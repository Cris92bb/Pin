import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../entities/task/state/task_state_notifier.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/task_text_formatter.dart';

/// Tab allowing users to format and copy Pin tasks as clean Markdown text notes.
class ExportTextTab extends ConsumerStatefulWidget {
  const ExportTextTab({super.key});

  @override
  ConsumerState<ExportTextTab> createState() => _ExportTextTabState();
}

class _ExportTextTabState extends ConsumerState<ExportTextTab> {
  String _selectedScope = 'all'; // 'all' | 'today' | 'backlog' | 'done'
  bool _copied = false;

  List<PinTask> _filterTasks(List<PinTask> allTasks) {
    switch (_selectedScope) {
      case 'today':
        return allTasks.where((t) => t.status == TaskStatus.today).toList();
      case 'backlog':
        return allTasks.where((t) => t.status == TaskStatus.backlog).toList();
      case 'done':
        return allTasks.where((t) => t.status == TaskStatus.done).toList();
      case 'all':
      default:
        return allTasks;
    }
  }

  Future<void> _copyText(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allTasks = ref.watch(taskStateProvider).tasks;
    final filtered = _filterTasks(allTasks);
    final markdownContent = TaskTextFormatter.formatTaskList(
      filtered,
      groupByStatus: _selectedScope == 'all',
    );

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildScopeChip('all', 'All Pins (${allTasks.length})', isDark),
              const SizedBox(width: 8),
              _buildScopeChip(
                'today',
                'Today (${allTasks.where((t) => t.status == TaskStatus.today).length})',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildScopeChip(
                'backlog',
                'Backlog (${allTasks.where((t) => t.status == TaskStatus.backlog).length})',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildScopeChip(
                'done',
                'Done (${allTasks.where((t) => t.status == TaskStatus.done).length})',
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preview Box
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(
                color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                markdownContent,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.45,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${filtered.length} task${filtered.length == 1 ? '' : 's'} ready to share',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            PinButton.primary(
              icon: _copied ? Icons.check_rounded : Icons.copy_all_rounded,
              text: _copied ? 'Copied!' : 'Copy Formatted Text',
              onPressed: filtered.isNotEmpty ? () => _copyText(markdownContent) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScopeChip(String scope, String label, bool isDark) {
    final isSelected = _selectedScope == scope;
    final activeBg = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final inactiveBg = isDark ? PinTokens.darkCardBg : PinTokens.surfaceColumn;
    final activeFg = isDark ? PinTokens.darkCanvasBg : Colors.white;
    final inactiveFg = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return InkWell(
      borderRadius: PinTokens.radiusSm,
      onTap: () => setState(() => _selectedScope = scope),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: PinTokens.radiusSm,
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
