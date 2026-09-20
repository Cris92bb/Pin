import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../entities/task/state/task_state_notifier.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/task_text_formatter.dart';

/// Tab for importing tasks directly from markdown bullet notes, checklists, or copied text.
class ImportTextTab extends ConsumerStatefulWidget {
  final VoidCallback onImportComplete;

  const ImportTextTab({
    super.key,
    required this.onImportComplete,
  });

  @override
  ConsumerState<ImportTextTab> createState() => _ImportTextTabState();
}

class _ImportTextTabState extends ConsumerState<ImportTextTab> {
  late final TextEditingController _textController;
  List<PinTask> _parsedTasks = [];
  TaskStatus _targetStatus = TaskStatus.today;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _textController.text = data.text!;
      _onTextChanged(data.text!);
    }
  }

  void _onTextChanged(String text) {
    setState(() {
      _parsedTasks = TaskTextFormatter.parseTextToTasks(
        text,
        defaultStatus: _targetStatus,
      );
    });
  }

  Future<void> _executeImport() async {
    if (_parsedTasks.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final notifier = ref.read(taskStateProvider.notifier);
      await notifier.importTasks(_parsedTasks, replaceAll: false);

      if (mounted) {
        widget.onImportComplete();
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header / Paste Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paste Notes or Checklist:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            PinButton(
              icon: Icons.paste_rounded,
              text: 'Paste Clipboard',
              isCompact: true,
              onPressed: _pasteFromClipboard,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Text area input
        TextField(
          controller: _textController,
          maxLines: 4,
          style: TextStyle(fontSize: 12, color: textPrimary),
          decoration: InputDecoration(
            hintText: '- [ ] Ship new feature (30m) #dev\n  - [ ] Write tests\n- [ ] Review sprint backlog',
            hintStyle: TextStyle(
              fontSize: 11,
              color: isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextTertiary,
            ),
            filled: true,
            fillColor: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: PinTokens.radiusMd,
              borderSide: BorderSide(
                color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
              ),
            ),
          ),
          onChanged: _onTextChanged,
        ),
        const SizedBox(height: 10),

        // Target Column Selector
        Row(
          children: [
            Text('Add to: ', style: TextStyle(fontSize: 11, color: textSecondary)),
            const SizedBox(width: 4),
            _buildStatusChip(TaskStatus.today, 'Today', isDark),
            const SizedBox(width: 6),
            _buildStatusChip(TaskStatus.backlog, 'Backlog', isDark),
          ],
        ),
        const SizedBox(height: 10),

        // Parsed tasks preview
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCanvasBg : PinTokens.surfaceColumn,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(
                color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
              ),
            ),
            child: _parsedTasks.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parsed ${_parsedTasks.length} Pin${_parsedTasks.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PinTokens.accentEmerald,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _parsedTasks.length,
                          itemBuilder: (context, index) {
                            final task = _parsedTasks[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Icon(
                                    task.status == TaskStatus.done
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 14,
                                    color: task.status == TaskStatus.done
                                        ? PinTokens.accentEmerald
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${task.title} (${task.estimatedMinutes}m)${task.tags.isNotEmpty ? ' ${task.tags.join(' ')}' : ''}${task.subtasks.isNotEmpty ? ' [${task.subtasks.length} subtasks]' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'Paste text above to auto-detect tasks, durations, and subtasks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton.primary(
              icon: Icons.add_task_rounded,
              text: _isImporting
                  ? 'Adding...'
                  : 'Add ${_parsedTasks.length} Pins to ${_targetStatus.label}',
              onPressed: _parsedTasks.isNotEmpty && !_isImporting
                  ? _executeImport
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(TaskStatus status, String label, bool isDark) {
    final isSelected = _targetStatus == status;
    final activeBg = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final inactiveBg = isDark ? PinTokens.darkCardBg : PinTokens.surfaceColumn;
    final activeFg = isDark ? PinTokens.darkCanvasBg : Colors.white;
    final inactiveFg = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return InkWell(
      borderRadius: PinTokens.radiusSm,
      onTap: () {
        setState(() {
          _targetStatus = status;
          _onTextChanged(_textController.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: PinTokens.radiusSm,
          border: Border.all(
            color: isSelected ? activeBg : (isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
