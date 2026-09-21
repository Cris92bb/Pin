import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_button.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Modal dialog presented when an incoming deep link containing shared pin tasks is received.
///
/// Previews the shared task's title, duration, tags, description, and atomic steps,
/// allowing the user to choose a target lane (Today or Backlog) before importing.
class ImportSharedPinModal extends ConsumerStatefulWidget {
  final List<PinTask> tasks;

  const ImportSharedPinModal({
    super.key,
    required this.tasks,
  });

  /// Displays the modal over the provided [context].
  static Future<void> show(
    BuildContext context, {
    required List<PinTask> tasks,
  }) async {
    if (tasks.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImportSharedPinModal(tasks: tasks),
    );
  }

  @override
  ConsumerState<ImportSharedPinModal> createState() => _ImportSharedPinModalState();
}

class _ImportSharedPinModalState extends ConsumerState<ImportSharedPinModal> {
  TaskStatus _targetStatus = TaskStatus.today;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(taskStateProvider).isTodayWipFull) {
      _targetStatus = TaskStatus.backlog;
    }
  }

  Future<void> _handleImport() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      final adjusted = widget.tasks.map((t) => t.copyWith(status: _targetStatus)).toList();
      await ref.read(taskStateProvider.notifier).importTasks(adjusted, replaceAll: false);
      if (mounted) {
        Navigator.of(context).pop();
        final msg = adjusted.length == 1
            ? 'Imported "${adjusted.first.title}" into ${_targetStatus.label}'
            : 'Imported ${adjusted.length} pins into ${_targetStatus.label}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
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
    final firstTask = widget.tasks.first;
    final isMulti = widget.tasks.length > 1;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
        maxWidth: 540,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? PinTokens.darkCardBg : PinTokens.surfaceModal,
        borderRadius: PinTokens.radiusLg,
        border: Border.all(
          color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
        ),
        boxShadow: isDark ? PinTokens.darkCardShadow : PinTokens.lightCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PinTokens.accentEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_rounded, size: 20, color: PinTokens.accentEmerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMulti ? 'Shared Pins Received' : 'Shared Pin Received',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      isMulti ? '${widget.tasks.length} tasks ready to import' : 'Someone shared a pin with you',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview Card
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
                borderRadius: PinTokens.radiusMd,
                border: Border.all(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstTask.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${firstTask.estimatedMinutes}m estimate',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    if (firstTask.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        firstTask.description,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                    if (firstTask.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Checklist (${firstTask.subtasks.length} steps):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      ...firstTask.subtasks.map((step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              step.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: step.isCompleted ? PinTokens.accentEmerald : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textPrimary,
                                  decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    if (isMulti) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Multiple tasks included',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PinTokens.accentEmerald),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Status Selector
          Row(
            children: [
              Text(
                'Add to:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(TaskStatus.today, 'Today', isDark),
              const SizedBox(width: 8),
              _buildStatusPill(TaskStatus.backlog, 'Backlog', isDark),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PinButton(
                text: 'Dismiss',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              PinButton.primary(
                icon: Icons.download_rounded,
                text: _isImporting
                    ? 'Importing...'
                    : 'Import to ${_targetStatus.label}',
                onPressed: _isImporting ? null : _handleImport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(TaskStatus status, String label, bool isDark) {
    final isSelected = _targetStatus == status;
    final activeBg = isDark ? PinTokens.darkActiveFocus : PinTokens.lightActiveFocus;
    final inactiveBg = isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg;
    final activeFg = isDark ? PinTokens.darkCanvasBg : Colors.white;
    final inactiveFg = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return InkWell(
      borderRadius: PinTokens.radiusSm,
      onTap: () => setState(() => _targetStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
