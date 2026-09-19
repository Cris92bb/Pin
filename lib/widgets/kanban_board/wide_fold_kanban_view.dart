import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/ai/ui/ai_task_breakdown_modal.dart';
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
  TaskStatus _currentDeck = TaskStatus.today;
  int _lastSlotIndex = 0;
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

    // Track which inactive slot (0 or 1) the newly active deck originated from
    if (activeDeck != _currentDeck) {
      final prevInactive =
          allStatuses.where((s) => s != _currentDeck).toList();
      final slotIdx = prevInactive.indexOf(activeDeck);
      if (slotIdx >= 0) {
        _lastSlotIndex = slotIdx;
      }
      _currentDeck = activeDeck;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          const gap = 14.0;

          // Flex allocation: flex 4 for active, flex 6 for inactive section
          final flexUnit = (availableWidth - gap) / 10.0;
          final activeWidth = flexUnit * 4.0;
          final inactiveSectionWidth = flexUnit * 6.0;
          final inactiveCardWidth = (inactiveSectionWidth - gap) / 2.0;

          // Center-to-center horizontal travel distance from active drawer to clicked inactive slot:
          final deltaXCenter0 =
              (activeWidth + inactiveCardWidth) / 2.0 + gap;
          final deltaXCenter1 = activeWidth / 2.0 +
              gap * 2.0 +
              1.5 * inactiveCardWidth;

          final targetPixelX =
              _lastSlotIndex == 1 ? deltaXCenter1 : deltaXCenter0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Inactive Drawers Section (rendered underneath so active drawer glides on top)
              Positioned(
                left: activeWidth + gap,
                top: 0,
                right: 0,
                bottom: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    // Two inactive drawers side-by-side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildInactiveSlot(
                            context,
                            status: inactiveStatuses[0],
                            taskState: taskState,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _buildInactiveSlot(
                            context,
                            status: inactiveStatuses[1],
                            taskState: taskState,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    // Overlay Panel for Focus Mode or Task Editor
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.linear,
                      switchOutCurve: Curves.linear,
                      layoutBuilder:
                          (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCubic,
                          reverseCurve: Curves.easeInOutCubic,
                        );
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.04),
                            end: Offset.zero,
                          ).animate(curved),
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: animation,
                              curve: const Interval(0.0, 0.85,
                                  curve: Curves.easeOut),
                              reverseCurve: const Interval(0.0, 0.85,
                                  curve: Curves.easeIn),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: activeTaskEditor != null
                          ? KeyedSubtree(
                              key: const ValueKey<String>('editor_overlay'),
                              child: _buildEditorOverlay(
                                context,
                                args: activeTaskEditor,
                                isDark: isDark,
                              ),
                            )
                          : (activeFocusTask != null
                              ? KeyedSubtree(
                                  key: ValueKey<String>(
                                      'focus_overlay_${activeFocusTask.id}'),
                                  child: _buildFocusOverlay(
                                    context,
                                    task: activeFocusTask,
                                    isDark: isDark,
                                  ),
                                )
                              : const SizedBox.shrink()),
                    ),
                  ],
                ),
              ),

              // 2. Active Drawer on the left (rendered on top so it glides across the screen from right to left!)
              Positioned(
                left: 0,
                top: 0,
                width: activeWidth,
                bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 650),
                  switchInCurve: Curves.linear,
                  switchOutCurve: Curves.linear,
                  layoutBuilder:
                      (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                      reverseCurve: Curves.easeInOutCubic,
                    );

                    // Cross-screen physical pixel slide:
                    // Incoming: starts at exact pixel position of clicked slot (targetPixelX) and slides left to 0.0!
                    // Outgoing: starts at 0.0 and slides right to targetPixelX!
                    final slideAnimation = Tween<Offset>(
                      begin: Offset(targetPixelX, 0.0),
                      end: Offset.zero,
                    ).animate(curved);

                    // Tactile 3D scale:
                    // Incoming: starts at 0.88 and expands into active foreground (1.0).
                    // Outgoing: shrinks from 1.0 down to 0.88 into inactive slot.
                    final scaleAnimation = Tween<double>(
                      begin: 0.88,
                      end: 1.0,
                    ).animate(curved);

                    // Subtle 3D perspective depth tilt during transit
                    final tiltAnimation = Tween<double>(
                      begin: -0.035,
                      end: 0.0,
                    ).animate(curved);

                    // Both cards remain fully visible throughout their cross-screen transit:
                    // Incoming starts at 0.85 (inactive opacity) and brightens to 1.0.
                    // Outgoing starts at 1.0 and smoothly eases to 0.85.
                    final opacityAnimation = Tween<double>(
                      begin: 0.85,
                      end: 1.0,
                    ).animate(curved);

                    return AnimatedBuilder(
                      animation: curved,
                      builder: (context, childWidget) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateY(tiltAnimation.value),
                          child: childWidget,
                        );
                      },
                      child: _PixelSlideTransition(
                        offset: slideAnimation,
                        child: ScaleTransition(
                          scale: scaleAnimation,
                          alignment: Alignment.center,
                          child: FadeTransition(
                            opacity: opacityAnimation,
                            child: child,
                          ),
                        ),
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
            ],
          );
        },
      ),
    );
  }

  /// Builds an inactive drawer slot with a subtle docking outline, smoothly receiving the arriving card.
  Widget _buildInactiveSlot(
    BuildContext context, {
    required TaskStatus status,
    required TaskListState taskState,
    required bool isDark,
  }) {
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg =
        isDark ? PinTokens.darkStackedTabBg : PinTokens.lightStackedTabBg;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft docking tray outline underneath the card
        Container(
          decoration: BoxDecoration(
            color: cardBg.withValues(alpha: 0.35),
            borderRadius: PinTokens.radiusDeck,
            border: Border.all(
              color: borderColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.linear,
          switchOutCurve: Curves.linear,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            // The outgoing drawer has lifted off and is sliding across the board in the top layer;
            // hide it from this slot to prevent any duplicate rendering.
            // The incoming drawer docks smoothly into place as the flight arrives.
            final isIncoming = child.key == ValueKey<TaskStatus>(status);
            if (isIncoming) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
              );
              return FadeTransition(
                opacity: fade,
                child: child,
              );
            } else {
              return const SizedBox.shrink();
            }
          },
          child: KeyedSubtree(
            key: ValueKey<TaskStatus>(status),
            child: _buildInactiveDrawer(
              context,
              status: status,
              taskState: taskState,
              isDark: isDark,
            ),
          ),
        ),
      ],
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
          // Drawer Header - unified 56px height with perfect baseline alignment
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _statusIcon(status),
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
                            _statusTitle(status),
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
                    _buildWipSlots(taskState, isDark),
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
                    tooltip: 'Capture Pin in ${_statusTitle(status)}',
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
                            child:
                                _buildEmptyState(status, isDark, textSecondary),
                          ),
                        );
                      },
                    ),
                  )
                : BouncyDrawerScrollWrapper(
                    controller: _activeScrollController,
                    child: ListView.builder(
                      controller: _activeScrollController,
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
                width: isHovered ? 1.4 : 1.2,
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
                // Inactive Header - unified 56px height perfectly matching active drawer
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          _statusIcon(status),
                          size: 19,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _statusTitle(status),
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
                                  color: isDark
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
                        if (status == TaskStatus.today) ...[
                          _buildWipSlots(taskState, isDark),
                          const SizedBox(width: 8),
                        ],
                        if (status == TaskStatus.done && tasks.isNotEmpty)
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
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
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
        key: ValueKey<String>('focus_${task.id}'),
        task: task,
        onExit: () {
          ref.read(activeFocusTaskProvider.notifier).state = null;
        },
        onEditTask: (t) async {
          ref.read(activeTaskEditorProvider.notifier).state =
              TaskEditorArgs(task: t);
        },
        onReanalyzeWithAi: (t) => AiTaskBreakdownModal.show(
          context,
          task: t,
          onOpenEditor: (edited) => TaskCrudModal.show(context, task: edited),
        ),
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

/// Animated widget translating child by explicit logical pixel offset.
class _PixelSlideTransition extends AnimatedWidget {
  final Widget child;

  const _PixelSlideTransition({
    required Animation<Offset> offset,
    required this.child,
  }) : super(listenable: offset);

  Animation<Offset> get offset => listenable as Animation<Offset>;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset.value,
      child: child,
    );
  }
}
