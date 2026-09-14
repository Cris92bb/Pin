import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/focus_mode/ui/focus_mode_view.dart';
import '../../features/task_crud/state/task_editor_state.dart';
import '../../features/task_crud/ui/task_crud_modal.dart';
import '../../shared/ui/pin_tokens.dart';
import 'bouncy_drawer_scroll_wrapper.dart';
import 'task_card.dart';

/// Responsive 3-drawer Kanban layout optimized for Web, Foldable devices, and wide screens.
///
/// Displays 3 drawers (Backlog, Today, Done):
/// - The focused/active drawer is wider (in primary section) with 100% opacity.
/// - The 2 inactive drawers are displayed side-by-side with subtle opacity.
/// - Tapping an inactive drawer smoothly switches places with the active one.
/// - When entering Focus Mode or creating/editing a task, the overlay panel slides
///   over the 2 inactive drawers, keeping the active queue visible beside it.
class WideFoldKanbanView extends ConsumerStatefulWidget {
  const WideFoldKanbanView({super.key});

  @override
  ConsumerState<WideFoldKanbanView> createState() => _WideFoldKanbanViewState();
}

class _WideFoldKanbanViewState extends ConsumerState<WideFoldKanbanView> {
  TaskStatus? _hoveredStatus;
  final ScrollController _activeScrollController = ScrollController();

  @override
  void dispose() {
    _activeScrollController.dispose();
    super.dispose();
  }

  String _statusTitle(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.today:
        return 'To Do (Today)';
      case TaskStatus.done:
        return 'Done';
    }
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return Icons.inventory_2_outlined;
      case TaskStatus.today:
        return Icons.bolt_rounded;
      case TaskStatus.done:
        return Icons.check_circle_outline_rounded;
    }
  }

  List<PinTask> _tasksForStatus(TaskListState state, TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return state.backlogTasks;
      case TaskStatus.today:
        return state.todayTasks;
      case TaskStatus.done:
        return state.doneTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskStateProvider);
    final activeDeck = ref.watch(activeDeckProvider);
    final activeFocusTask = ref.watch(activeFocusTaskProvider);
    final activeTaskEditor = ref.watch(activeTaskEditorProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const allStatuses = [TaskStatus.backlog, TaskStatus.today, TaskStatus.done];
    final inactiveStatuses =
        allStatuses.where((s) => s != activeDeck).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary / Focused Drawer (a bit wider, e.g. flex 4)
          Expanded(
            flex: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.04, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<TaskStatus>(activeDeck),
                child: _buildActiveDrawer(
                  context,
                  status: activeDeck,
                  taskState: taskState,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Secondary Section: 2 Inactive Drawers with Overlay for Focus/Editor (flex 6)
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Underneath: 2 Inactive Drawers side-by-side
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '${inactiveStatuses[0].name}_${inactiveStatuses[1].name}',
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildInactiveDrawer(
                            context,
                            status: inactiveStatuses[0],
                            taskState: taskState,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildInactiveDrawer(
                            context,
                            status: inactiveStatuses[1],
                            taskState: taskState,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overlay Panel: Focus Mode or Task Editor (hiding the 2 inactive drawers beneath)
                if (activeFocusTask != null)
                  Positioned.fill(
                    child: _buildFocusOverlay(
                      context,
                      task: activeFocusTask,
                      isDark: isDark,
                    ),
                  )
                else if (activeTaskEditor != null)
                  Positioned.fill(
                    child: _buildEditorOverlay(
                      context,
                      args: activeTaskEditor,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the focused, active drawer container
  Widget _buildActiveDrawer(
    BuildContext context, {
    required TaskStatus status,
    required TaskListState taskState,
    required bool isDark,
  }) {
    final tasks = _tasksForStatus(taskState, status);
    final isToday = status == TaskStatus.today;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkSheetBg : PinTokens.lightSheetBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.6 : 1.2,
        ),
        boxShadow: isDark
            ? PinTokens.darkCardShadow
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
            child: Row(
              children: [
                Icon(
                  _statusIcon(status),
                  size: 20,
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
                      Text(
                        _statusTitle(status),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                  _buildWipSlots(taskState, isDark),
                  const SizedBox(width: 8),
                ],

                // Quick Add button for this drawer
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  color: isDark
                      ? PinTokens.darkTextSecondary
                      : PinTokens.lightFabBg,
                  splashRadius: 18,
                  tooltip: 'Capture Pin in ${_statusTitle(status)}',
                  onPressed: () {
                    ref.read(activeTaskEditorProvider.notifier).state =
                        TaskEditorArgs(defaultStatus: status);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Task list or empty state
          Expanded(
            child: tasks.isEmpty
                ? BouncyDrawerScrollWrapper(
                    controller: _activeScrollController,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: _activeScrollController,
                          physics: const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: _buildEmptyState(status, isDark, textSecondary),
                          ),
                        );
                      },
                    ),
                  )
                : BouncyDrawerScrollWrapper(
                    controller: _activeScrollController,
                    child: ListView.builder(
                      controller: _activeScrollController,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
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

  /// Builds an inactive drawer with subtle opacity and click-to-switch interaction
  Widget _buildInactiveDrawer(
    BuildContext context, {
    required TaskStatus status,
    required TaskListState taskState,
    required bool isDark,
  }) {
    final tasks = _tasksForStatus(taskState, status);
    final isHovered = _hoveredStatus == status;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg =
        isDark ? PinTokens.darkStackedTabBg : PinTokens.lightStackedTabBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredStatus = status),
      onExit: (_) => setState(() => _hoveredStatus = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Switch places with the active drawer!
          ref.read(activeDeckProvider.notifier).state = status;
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isHovered ? 0.90 : 0.65,
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: PinTokens.radiusDeck,
              border: Border.all(
                color: isHovered
                    ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                    : borderColor,
                width: isHovered ? 1.4 : 1.0,
              ),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Inactive Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 17,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _statusTitle(status),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      if (status == TaskStatus.done && tasks.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                          color: textSecondary,
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                          tooltip: 'Clear Done Tasks',
                          onPressed: () {
                            ref.read(taskStateProvider.notifier).clearDoneTasks();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Task preview list
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            status == TaskStatus.done
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
                          absorbing: true, // Click anywhere activates drawer
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              return TaskCard(task: tasks[index]);
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

  /// WIP slots indicator for active Today drawer
  Widget _buildWipSlots(TaskListState state, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(state.wipLimit, (index) {
        final isFilled = index < state.todayTasks.length;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (isDark
                    ? PinTokens.darkActiveFocus
                    : PinTokens.lightActiveFocus)
                : (isDark
                    ? PinTokens.darkBorder
                    : PinTokens.lightBorder),
          ),
        );
      }),
    );
  }

  /// Empty state display for active drawer
  Widget _buildEmptyState(
      TaskStatus status, bool isDark, Color textSecondary) {
    final message = status == TaskStatus.today
        ? 'No pins for Today.\nPull a task from Backlog or capture a new one!'
        : (status == TaskStatus.done
            ? 'No completed tasks yet.\nFinish active pins to see them here!'
            : 'Backlog is clear.\nAll ideas organized!');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _statusIcon(status),
              size: 36,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Overlay containing Focus Mode view placed above the 2 inactive drawers
  Widget _buildFocusOverlay(
    BuildContext context, {
    required PinTask task,
    required bool isDark,
  }) {
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final sheetBg = isDark ? PinTokens.darkSheetBg : PinTokens.lightSheetBg;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.6 : 1.2,
        ),
        boxShadow: isDark
            ? PinTokens.darkCardShadow
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FocusModeView(
        task: task,
        onExit: () {
          ref.read(activeFocusTaskProvider.notifier).state = null;
        },
      ),
    );
  }

  /// Overlay containing Task Create / Edit panel placed above the 2 inactive drawers
  Widget _buildEditorOverlay(
    BuildContext context, {
    required TaskEditorArgs args,
    required bool isDark,
  }) {
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final frameBg =
        isDark ? PinTokens.darkPhoneFrameBg : PinTokens.lightCardBg;

    return Container(
      decoration: BoxDecoration(
        color: frameBg,
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.6 : 1.2,
        ),
        boxShadow: isDark
            ? PinTokens.darkCardShadow
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: TaskCrudModal(
        initialTask: args.task,
        defaultStatus: args.defaultStatus,
        autoTriggerAi: args.autoTriggerAi,
        asDialog: false,
        onClose: () {
          ref.read(activeTaskEditorProvider.notifier).state = null;
        },
      ),
    );
  }
}
