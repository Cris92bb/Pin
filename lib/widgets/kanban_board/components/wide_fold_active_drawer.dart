import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../features/task_crud/state/task_editor_state.dart';
import '../../../shared/ui/pin_tokens.dart';
import '../bouncy_drawer_scroll_wrapper.dart';
import '../task_card.dart';
import 'wide_fold_empty_state.dart';
import 'wide_fold_helpers.dart';
import 'wide_fold_wip_slots.dart';

/// The active, expanded Kanban drawer in the wide fold layout.
class WideFoldActiveDrawer extends ConsumerWidget {
  /// The task status represented by this drawer.
  final TaskStatus status;

  /// Global task list state.
  final TaskListState taskState;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Scroll controller for the active drawer list.
  final ScrollController scrollController;

  /// Creates a [WideFoldActiveDrawer].
  const WideFoldActiveDrawer({
    super.key,
    required this.status,
    required this.taskState,
    required this.isDark,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = WideFoldHelpers.tasksForStatus(taskState, status);
    final isToday = status == TaskStatus.today;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkSheetBg : PinTokens.lightSheetBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusDeck,
        boxShadow: isDark
            ? PinTokens.darkCardShadow
            : [
                BoxShadow(
                  color: PinTokens.shadowSlate.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header - unified 56px height with perfect baseline alignment
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    WideFoldHelpers.statusIcon(status),
                    size: 19,
                    color: isToday
                        ? (isDark
                            ? PinTokens.darkActiveFocus
                            : PinTokens.lightActiveFocus)
                        : textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            WideFoldHelpers.statusTitle(status),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
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
                            color: isDark
                                ? PinTokens.darkCardBg
                                : PinTokens.lightTagBg,
                            borderRadius: PinTokens.radiusFull,
                            border: Border.all(color: borderColor, width: 1),
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
                  // If Today: Show WIP tracker
                  if (isToday) ...[
                    WideFoldWipSlots(state: taskState, isDark: isDark),
                    const SizedBox(width: 8),
                  ],
                  // Quick Add button for this drawer
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    color: isDark
                        ? PinTokens.darkTextSecondary
                        : PinTokens.lightFabBg,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip:
                        'Capture Pin in ${WideFoldHelpers.statusTitle(status)}',
                    onPressed: () {
                      ref.read(activeTaskEditorProvider.notifier).state =
                          TaskEditorArgs(defaultStatus: status);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Task list or empty state
          Expanded(
            child: tasks.isEmpty
                ? BouncyDrawerScrollWrapper(
                    controller: scrollController,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: WideFoldEmptyState(
                              status: status,
                              isDark: isDark,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : BouncyDrawerScrollWrapper(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final t = tasks[index];
                        return TaskCard(
                          task: t,
                          onEdit: () {
                            ref.read(activeTaskEditorProvider.notifier).state =
                                TaskEditorArgs(task: t);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
