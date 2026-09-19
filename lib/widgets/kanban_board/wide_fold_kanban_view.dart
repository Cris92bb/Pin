import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/ai/ui/ai_task_breakdown_modal.dart';
import '../../features/focus_mode/ui/focus_mode_view.dart';
import '../../features/task_crud/state/task_editor_state.dart';
import '../../features/task_crud/ui/task_crud_modal.dart';
import 'package:pin/shared/lib/date_helpers.dart';
import '../../shared/ui/pin_tokens.dart';
import 'bouncy_drawer_scroll_wrapper.dart';
import 'task_card.dart';

/// Responsive 3-drawer Kanban layout optimized for Web, Foldable devices, and wide screens.
///
/// Displays 3 drawers (Backlog, Today, Done):
/// - The focused/active drawer is wider (in primary section) with 100% opacity.
/// - The 2 inactive drawers are displayed side-by-side with subtle opacity.
/// - Tapping an inactive drawer smoothly glides from its position on the right across to the
///   active position on the left, expanding into full width, while the active drawer glides
///   into the vacated slot and docks cleanly.
/// - When entering Focus Mode or creating/editing a task, the overlay panel slides
///   over the 2 inactive drawers, keeping the active queue visible beside it.
class WideFoldKanbanView extends ConsumerStatefulWidget {
  const WideFoldKanbanView({super.key});

  @override
  ConsumerState<WideFoldKanbanView> createState() => _WideFoldKanbanViewState();
}

class _WideFoldKanbanViewState extends ConsumerState<WideFoldKanbanView>
    with SingleTickerProviderStateMixin {
  TaskStatus? _hoveredStatus;
  final ScrollController _activeScrollController = ScrollController();

  late final AnimationController _transitionController;
  late final CurvedAnimation _transitionCurve;

  TaskStatus _activeStatus = TaskStatus.today;
  TaskStatus? _departingStatus;
  TaskStatus? _arrivingStatus;

  @override
  void initState() {
    super.initState();
    _activeStatus = ref.read(activeDeckProvider);
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _transitionCurve = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _activeScrollController.dispose();
    super.dispose();
  }

  void _selectInactiveDrawer(TaskStatus status) {
    if (_transitionController.isAnimating) return;
    ref.read(activeDeckProvider.notifier).state = status;
    _startDrawerTransition(status);
  }

  void _startDrawerTransition(TaskStatus newActiveStatus) {
    if (newActiveStatus == _activeStatus) return;

    _transitionController.value = 0.0;
    setState(() {
      _departingStatus = _activeStatus;
      _arrivingStatus = newActiveStatus;
    });

    _transitionController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _activeStatus = newActiveStatus;
        _departingStatus = null;
        _arrivingStatus = null;
      });
    });
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

    // Keep _activeStatus in sync if activeDeckProvider was changed externally while idle
    if (activeDeck != _activeStatus && _arrivingStatus == null && !_transitionController.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && activeDeck != _activeStatus && _arrivingStatus == null) {
          _startDrawerTransition(activeDeck);
        }
      });
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const allStatuses = [TaskStatus.backlog, TaskStatus.today, TaskStatus.done];
    final inactiveStatuses =
        allStatuses.where((s) => s != _activeStatus).toList();


    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Left Pane: Persistent Active Column (flex: 3) ───
          Expanded(
            flex: 3,
            child: _buildActiveDrawerPane(
              context,
              taskState: taskState,
              isDark: isDark,
              inactiveStatuses: inactiveStatuses,
            ),
          ),

          const SizedBox(width: 14),

          // ─── Right Pane: Dynamic Content (flex: 5) ───
          Expanded(
            flex: 5,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
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
                    begin: const Offset(0.04, 0.0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve:
                          const Interval(0.0, 0.85, curve: Curves.easeOut),
                      reverseCurve:
                          const Interval(0.0, 0.85, curve: Curves.easeIn),
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
                      : KeyedSubtree(
                          key: const ValueKey<String>('inactive_drawers'),
                          child: _buildInactiveDrawersPane(
                            context,
                            taskState: taskState,
                            isDark: isDark,
                            inactiveStatuses: inactiveStatuses,
                          ),
                        )),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the left pane containing the active drawer with swap animation support.
  Widget _buildActiveDrawerPane(
    BuildContext context, {
    required TaskListState taskState,
    required bool isDark,
    required List<TaskStatus> inactiveStatuses,
  }) {
    return AnimatedBuilder(
      animation: _transitionCurve,
      builder: (context, _) {
        final isAnimating =
            _transitionController.isAnimating || _arrivingStatus != null;
        final t = _transitionCurve.value;

        if (!isAnimating) {
          return _buildActiveDrawer(
            context,
            status: _activeStatus,
            taskState: taskState,
            isDark: isDark,
          );
        }

        // During swap: stack departing (fading out) and arriving (sliding in)
        return Stack(
          fit: StackFit.expand,
          children: [
            // Departing drawer (shrinks and fades out to the right)
            Opacity(
              opacity: (1.0 - t).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(40.0 * t, 0),
                child: _buildActiveDrawer(
                  context,
                  status: _departingStatus!,
                  taskState: taskState,
                  isDark: isDark,
                ),
              ),
            ),

            // Arriving drawer (slides in from the right with elevation)
            Transform.translate(
              offset: Offset(60.0 * (1.0 - t), 0),
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: PinTokens.radiusDeck,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? Colors.black
                                : const Color(0xFF0F172A))
                            .withValues(alpha: 0.25 * (1.0 - t)),
                        blurRadius: 20,
                        offset: const Offset(-6, 8),
                      ),
                    ],
                  ),
                  child: _buildActiveDrawer(
                    context,
                    status: _arrivingStatus!,
                    taskState: taskState,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the right pane showing two inactive drawers side-by-side.
  Widget _buildInactiveDrawersPane(
    BuildContext context, {
    required TaskListState taskState,
    required bool isDark,
    required List<TaskStatus> inactiveStatuses,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildInactiveDrawer(
            context,
            status: inactiveStatuses[0],
            taskState: taskState,
            isDark: isDark,
            onSelect: () => _selectInactiveDrawer(inactiveStatuses[0]),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildInactiveDrawer(
            context,
            status: inactiveStatuses[1],
            taskState: taskState,
            isDark: isDark,
            onSelect: () => _selectInactiveDrawer(inactiveStatuses[1]),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusDeck,
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
    VoidCallback? onSelect,
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
          if (onSelect != null) {
            onSelect();
          } else {
            ref.read(activeDeckProvider.notifier).state = status;
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isHovered ? 0.85 : 0.50,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: PinTokens.radiusDeck,
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
            foregroundDecoration: BoxDecoration(
              borderRadius: PinTokens.radiusDeck,
              border: Border.all(
                color: isHovered
                    ? (isDark ? PinTokens.accentEmerald : PinTokens.lightFabBg)
                    : borderColor,
                width: isHovered ? 1.4 : 1.2,
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
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 36),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              return _buildCompactCard(tasks[index], isDark);
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

  /// Lightweight compact card for inactive drawers — read-only, no interactive buttons.
  Widget _buildCompactCard(PinTask task, bool isDark) {
    final isDone = task.status == TaskStatus.done;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    // Primary tag color pip
    Color? tagPipColor;
    if (task.tags.isNotEmpty) {
      final firstTag = task.tags.first.toLowerCase().trim();
      if (firstTag.contains('dev') || firstTag.contains('code')) {
        tagPipColor = isDark ? PinTokens.darkActiveFocus : PinTokens.accentViolet;
      } else if (firstTag.contains('design') || firstTag.contains('ui')) {
        tagPipColor = PinTokens.accentSky;
      } else if (firstTag.contains('bug') || firstTag.contains('fix')) {
        tagPipColor = PinTokens.accentRose;
      } else if (firstTag.contains('doc') || firstTag.contains('write')) {
        tagPipColor = PinTokens.accentAmber;
      } else {
        tagPipColor = PinTokens.accentEmerald;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusCard,
        border: isDark ? Border.all(color: borderColor, width: 1.0) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF1A241E).withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title — 2 lines max, no interactive controls
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDone
                  ? (isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextTertiary)
                  : textPrimary,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor:
                  isDark ? PinTokens.darkTextMuted : PinTokens.lightTextTertiary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Minimal metadata: energy pip + tag pip
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Energy label as small text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? PinTokens.darkSheetBg : PinTokens.lightTagBg,
                  borderRadius: PinTokens.radiusFull,
                ),
                child: Text(
                  task.energyDisplayLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),

              // Duration
              Text(
                DateHelpers.formatMinutes(task.estimatedMinutes),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),

              // Tag pip (colored dot for the first tag category)
              if (tagPipColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tagPipColor,
                  ),
                ),
            ],
          ),
        ],
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: PinTokens.radiusDeck,
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
      foregroundDecoration: BoxDecoration(
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.6 : 1.2,
        ),
      ),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: frameBg,
        borderRadius: PinTokens.radiusDeck,
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
      foregroundDecoration: BoxDecoration(
        borderRadius: PinTokens.radiusDeck,
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.6 : 1.2,
        ),
      ),
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
