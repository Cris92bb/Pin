import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wide_fold_compact_card.dart';
import 'wide_fold_helpers.dart';
import 'wide_fold_wip_slots.dart';

/// Inactive drawer with subtle opacity and click-to-dock interaction.
class WideFoldInactiveDrawer extends ConsumerStatefulWidget {
  /// The task status represented by this drawer.
  final TaskStatus status;

  /// Global task state for count badges and task list.
  final TaskListState taskState;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Optional callback invoked when the user selects this drawer.
  final VoidCallback? onSelect;

  /// Creates a [WideFoldInactiveDrawer].
  const WideFoldInactiveDrawer({
    super.key,
    required this.status,
    required this.taskState,
    required this.isDark,
    this.onSelect,
  });

  @override
  ConsumerState<WideFoldInactiveDrawer> createState() =>
      _WideFoldInactiveDrawerState();
}

class _WideFoldInactiveDrawerState
    extends ConsumerState<WideFoldInactiveDrawer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tasks = WideFoldHelpers.tasksForStatus(widget.taskState, widget.status);
    final borderColor =
        widget.isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = widget.isDark
        ? PinTokens.darkStackedTabBg
        : PinTokens.lightStackedTabBg;
    final textPrimary = widget.isDark
        ? PinTokens.darkTextPrimary
        : PinTokens.lightTextPrimary;
    final textSecondary = widget.isDark
        ? PinTokens.darkTextSecondary
        : PinTokens.lightTextSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onSelect != null) {
            widget.onSelect!();
          } else {
            ref.read(activeDeckProvider.notifier).state = widget.status;
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _isHovered ? 0.85 : 0.50,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: PinTokens.radiusDeck,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: PinTokens.shadowSlate.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: PinTokens.radiusDeck,
              border: Border.all(
                color: _isHovered
                    ? (widget.isDark
                        ? PinTokens.accentEmerald
                        : PinTokens.lightFabBg)
                    : borderColor,
                width: _isHovered ? 1.4 : 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Inactive Header - unified 56px height perfectly matching active drawer
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          WideFoldHelpers.statusIcon(widget.status),
                          size: 19,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  WideFoldHelpers.statusTitle(widget.status),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Count Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? PinTokens.darkCardBg
                                      : PinTokens.lightTagBg,
                                  borderRadius: PinTokens.radiusFull,
                                  border:
                                      Border.all(color: borderColor, width: 1),
                                ),
                                child: Text(
                                  '${tasks.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.status == TaskStatus.today) ...[
                          WideFoldWipSlots(
                            state: widget.taskState,
                            isDark: widget.isDark,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.status == TaskStatus.done && tasks.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_outlined,
                                size: 17),
                            color: textSecondary,
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            tooltip: 'Clear Done Tasks',
                            onPressed: () {
                              ref
                                  .read(taskStateProvider.notifier)
                                  .clearDoneTasks();
                            },
                          )
                        else
                          const SizedBox(width: 32, height: 32),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                // Task preview list
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            widget.status == TaskStatus.done
                                ? 'No completed tasks yet'
                                : 'Backlog empty',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : AbsorbPointer(
                          absorbing: true,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 36),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              return WideFoldCompactCard(
                                task: tasks[index],
                                isDark: widget.isDark,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
