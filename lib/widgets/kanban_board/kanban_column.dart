import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/task_crud/ui/task_crud_modal.dart';
import '../../shared/ui/pin_button.dart';
import '../../shared/ui/pin_tokens.dart';
import '../../shared/ui/wip_badge.dart';
import 'task_card.dart';

/// Single Kanban column with drag target support, WIP badge, and collapsible states.
class KanbanColumn extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final TaskStatus status;
  final List<PinTask> tasks;
  final bool isWipEnforced;
  final int? wipLimit;
  final bool isCollapsible;
  final bool initialCollapsed;
  final VoidCallback? onClear;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.tasks,
    this.isWipEnforced = false,
    this.wipLimit,
    this.isCollapsible = false,
    this.initialCollapsed = false,
    this.onClear,
  });

  @override
  ConsumerState<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<KanbanColumn> {
  late bool _isCollapsed;
  bool _isDragTargetActive = false;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  void _onQuickAdd() {
    TaskCrudModal.show(
      context,
      defaultStatus: widget.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.tasks.length;
    final isToday = widget.status == TaskStatus.today;

    if (_isCollapsed) {
      return _buildCollapsedColumn(count);
    }

    return DragTarget<PinTask>(
      onWillAcceptWithDetails: (details) {
        final draggedTask = details.data;
        if (draggedTask.status == widget.status) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        final draggedTask = details.data;
        final notifier = ref.read(taskStateProvider.notifier);
        switch (widget.status) {
          case TaskStatus.today:
            notifier.moveToToday(draggedTask.id);
            break;
          case TaskStatus.backlog:
            notifier.moveToBacklog(draggedTask.id);
            break;
          case TaskStatus.done:
            notifier.moveToDone(draggedTask.id);
            break;
        }
        setState(() => _isDragTargetActive = false);
      },
      onMove: (_) {
        if (!_isDragTargetActive) {
          setState(() => _isDragTargetActive = true);
        }
      },
      onLeave: (_) {
        if (_isDragTargetActive) {
          setState(() => _isDragTargetActive = false);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: PinTokens.animFast,
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: _isDragTargetActive
                ? PinTokens.surfaceColumn.withValues(alpha: 0.9)
                : PinTokens.surfaceColumn,
            borderRadius: PinTokens.radiusLg,
            border: Border.all(
              color: _isDragTargetActive
                  ? PinTokens.accentViolet
                  : (isToday &&
                          widget.wipLimit != null &&
                          count >= widget.wipLimit!
                      ? PinTokens.accentAmber.withValues(alpha: 0.4)
                      : PinTokens.borderDefault.withValues(alpha: 0.6)),
              width: _isDragTargetActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Column Header
              _buildHeader(count, isToday),

              // Divider
              const Divider(
                height: 1,
                thickness: 1,
                color: PinTokens.borderSubtle,
              ),

              // Task List Area
              Expanded(
                child: widget.tasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: widget.tasks.length,
                        itemBuilder: (context, index) {
                          final task = widget.tasks[index];
                          return Draggable<PinTask>(
                            data: task,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 320,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: TaskCard(task: task),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCard(task: task),
                            ),
                            child: TaskCard(task: task),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count, bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            widget.icon,
            size: 17,
            color: isToday
                ? PinTokens.accentEmerald
                : (widget.status == TaskStatus.done
                    ? PinTokens.accentEmerald
                    : PinTokens.accentSky),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PinTokens.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // WIP Badge or count pill
          if (isToday && widget.wipLimit != null) ...[
            WipBadge(count: count, limit: widget.wipLimit!),
            const SizedBox(width: 6),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: PinTokens.canvasBg,
                borderRadius: PinTokens.radiusFull,
                border: Border.all(color: PinTokens.borderSubtle),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PinTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Quick Add
          if (widget.status != TaskStatus.done)
            PinButton.icon(
              icon: Icons.add_rounded,
              tooltip: 'Add to ${widget.title}',
              onPressed: _onQuickAdd,
            ),

          // Clear Done button
          if (widget.status == TaskStatus.done && widget.onClear != null && count > 0)
            PinButton.icon(
              icon: Icons.delete_sweep_rounded,
              tooltip: 'Archive all done tasks',
              onPressed: widget.onClear,
            ),

          // Collapse Toggle
          if (widget.isCollapsible)
            PinButton.icon(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Collapse column',
              onPressed: () => setState(() => _isCollapsed = true),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    switch (widget.status) {
      case TaskStatus.today:
        message = 'Zero cognitive load.\nAdd up to 5 prioritized tasks.';
        icon = Icons.bolt_outlined;
        break;
      case TaskStatus.backlog:
        message = 'Icebox is clear.\nCapture future ideas here.';
        icon = Icons.all_inbox_rounded;
        break;
      case TaskStatus.done:
        message = 'Nothing completed yet.\nComplete tasks in Focus Mode!';
        icon = Icons.done_all_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: PinTokens.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: PinTokens.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedColumn(int count) {
    return InkWell(
      onTap: () => setState(() => _isCollapsed = false),
      borderRadius: PinTokens.radiusLg,
      child: Container(
        width: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: PinTokens.surfaceColumn.withValues(alpha: 0.5),
          borderRadius: PinTokens.radiusLg,
          border: Border.all(color: PinTokens.borderDefault.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(widget.icon, size: 16, color: PinTokens.textSecondary),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: PinTokens.canvasBg,
                borderRadius: PinTokens.radiusFull,
                border: Border.all(color: PinTokens.borderSubtle),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PinTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PinTokens.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: PinTokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
