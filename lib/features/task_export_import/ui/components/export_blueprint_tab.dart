import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../entities/task/state/task_state_notifier.dart';
import 'package:pin/shared/lib/blueprint_codec.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';

/// Tab for exporting portable base64 / JSON blueprints for offline cross-device sync.
class ExportBlueprintTab extends ConsumerStatefulWidget {
  const ExportBlueprintTab({super.key});

  @override
  ConsumerState<ExportBlueprintTab> createState() => _ExportBlueprintTabState();
}

class _ExportBlueprintTabState extends ConsumerState<ExportBlueprintTab> {
  String _selectedScope = 'all'; // 'all' | 'today' | 'backlog'
  bool _copied = false;

  List<PinTask> _filterTasks(List<PinTask> allTasks) {
    switch (_selectedScope) {
      case 'today':
        return allTasks.where((t) => t.status == TaskStatus.today).toList();
      case 'backlog':
        return allTasks.where((t) => t.status == TaskStatus.backlog).toList();
      case 'all':
      default:
        return allTasks;
    }
  }

  Future<void> _copyToClipboard(String content) async {
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

    final jsonList = filtered.map((t) => t.toJson()).toList();
    final blueprint = filtered.isNotEmpty ? BlueprintCodec.encodeTasks(jsonList) : '';

    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildScopeChip('all', 'All Tasks (${allTasks.length})', isDark),
              const SizedBox(width: 8),
              _buildScopeChip(
                'today',
                'Today Only (${allTasks.where((t) => t.status == TaskStatus.today).length})',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildScopeChip(
                'backlog',
                'Backlog Only (${allTasks.where((t) => t.status == TaskStatus.backlog).length})',
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Blueprint Code Box
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
                blueprint.isNotEmpty
                    ? blueprint
                    : '// No tasks found matching current filter.',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: PinTokens.accentEmerald,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Footer Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${filtered.length} task${filtered.length == 1 ? '' : 's'} in blueprint',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            PinButton.primary(
              icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
              text: _copied ? 'Copied Blueprint!' : 'Copy Blueprint Code',
              onPressed: blueprint.isNotEmpty ? () => _copyToClipboard(blueprint) : null,
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
