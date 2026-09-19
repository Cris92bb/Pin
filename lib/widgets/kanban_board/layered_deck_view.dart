import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../shared/ui/pin_tokens.dart';
import 'bouncy_drawer_scroll_wrapper.dart';
import 'task_card.dart';

/// Layered Card Deck Kanban View matching the companion app screenshot.
///
/// Drawers/Columns are rendered as a tactile stack of physical index cards / sheets
/// with fluid Apple-spring 3D perspective transitions between drawers, cascading card
/// reveals, tactile drawer pull grips, interactive tabs, and swipe gestures.
class LayeredDeckView extends ConsumerStatefulWidget {
  const LayeredDeckView({super.key});

  @override
  ConsumerState<LayeredDeckView> createState() => _LayeredDeckViewState();
}

class _LayeredDeckViewState extends ConsumerState<LayeredDeckView>
    with SingleTickerProviderStateMixin {
  TaskStatus _currentDeck = TaskStatus.today;
  late final AnimationController _horizontalEdgeNudgeController;
  Animation<double>? _horizontalNudgeAnimation;
  double _horizontalNudge = 0.0;

  @override
  void initState() {
    super.initState();
    _horizontalEdgeNudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..addListener(() {
        if (_horizontalNudgeAnimation != null) {
          setState(() {
            _horizontalNudge = _horizontalNudgeAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _horizontalEdgeNudgeController.dispose();
    super.dispose();
  }


  void _triggerHorizontalEdgeNudge(int delta) {
    // delta < 0: attempted swipe right past Backlog
    // delta > 0: attempted swipe left past Done
    final offset = delta < 0 ? 8.0 : -8.0;
    _horizontalEdgeNudgeController.stop();
    setState(() {
      _horizontalNudge = offset;
    });
    _horizontalNudgeAnimation = Tween<double>(
      begin: _horizontalNudge,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _horizontalEdgeNudgeController,
        curve: const Cubic(0.175, 0.885, 0.32, 1.275),
      ),
    );
    _horizontalEdgeNudgeController.forward(from: 0.0);
  }

  void _navigateDrawer(int delta) {
    const order = [TaskStatus.backlog, TaskStatus.today, TaskStatus.done];
    final currentIdx = order.indexOf(ref.read(activeDeckProvider));
    final targetIdx = currentIdx + delta;
    if (targetIdx >= 0 && targetIdx < order.length) {
      ref.read(activeDeckProvider.notifier).state = order[targetIdx];
    } else {
      _triggerHorizontalEdgeNudge(delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskStateProvider);
    final activeDeck = ref.watch(activeDeckProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final cardBg = isDark ? PinTokens.darkSheetBg : PinTokens.lightSheetBg;
    final textPrimary =
        isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary =
        isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;


    // Determine the order of stacked background tabs vs active sheet
    final allTabs = [TaskStatus.backlog, TaskStatus.done, TaskStatus.today];
    final inactiveTabs = allTabs.where((status) => status != activeDeck).toList();

    // Compute exact vertical origin of newly active deck directly from its tab slot
    double targetYOffset = -72.0;
    if (activeDeck != _currentDeck) {
      final prevInactiveTabs = allTabs.where((status) => status != _currentDeck).toList();
      final slotIndex = prevInactiveTabs.indexOf(activeDeck);
      targetYOffset = slotIndex == 1 ? -36.0 : -72.0;
      _currentDeck = activeDeck;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Tab 0 (full height card stacked behind)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: _InactiveTabCard(
            status: inactiveTabs[0],
            state: state,
            isDark: isDark,
            borderColor: borderColor,
            cardBg: isDark ? PinTokens.darkStackedTabBg : PinTokens.lightStackedTabBg,
            hoverBg: isDark ? const Color(0xFF1E242C) : const Color(0xFFD6DCCF),
            textPrimary: textPrimary,
            onTap: () {
              ref.read(activeDeckProvider.notifier).state = inactiveTabs[0];
            },
          ),
        ),

        // Background Tab 1 (full height card stacked behind)
        Positioned(
          top: 36,
          left: 0,
          right: 0,
          bottom: 0,
          child: _InactiveTabCard(
            status: inactiveTabs[1],
            state: state,
            isDark: isDark,
            borderColor: borderColor,
            cardBg: isDark ? PinTokens.darkStackedTabBg : PinTokens.lightStackedTabBg,
            hoverBg: isDark ? const Color(0xFF1E242C) : const Color(0xFFD6DCCF),
            textPrimary: textPrimary,
            onTap: () {
              ref.read(activeDeckProvider.notifier).state = inactiveTabs[1];
            },
          ),
        ),

        // Active Foreground Sheet with luxurious 3D perspective spring drawer transition
        Positioned(
          top: 72,
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(_horizontalNudge, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
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
              // Fluid ease-in-out curve for natural physical drawer motion
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
                reverseCurve: Curves.easeInOutCubic,
              );

              // Exact pixel slide matching the clicked tab's slot:
              // Incoming child: slides DOWN from its exact tab slot (-72px or -36px) into foreground (0px).
              // Outgoing child: slides UP from foreground directly towards the tab slot.
              final slideAnimation = Tween<Offset>(
                begin: Offset(0.0, targetYOffset),
                end: Offset.zero,
              ).animate(curved);

              // Tactile scale transition:
              // Incoming child: expands from 0.88 up to 1.0 (becomes larger into foreground).
              // Outgoing child: shrinks from 1.0 down to 0.88 (recedes into background).
              final scaleAnimation = Tween<double>(
                begin: 0.88,
                end: 1.0,
              ).animate(curved);

              // Synchronized opacity fade:
              // Incoming child: starts fading in smoothly across the first 70% of travel.
              // Outgoing child: holds presence as it starts sliding back, then dissolves into stack.
              final fadeAnimation = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.70, curve: Curves.easeInOut),
                reverseCurve: const Interval(0.30, 1.0, curve: Curves.easeInOut),
              );

              // 3D perspective depth tilt
              final tiltAnimation = Tween<double>(
                begin: -0.025,
                end: 0.0,
              ).animate(curved);

              return AnimatedBuilder(
                animation: curved,
                builder: (context, childWidget) {
                  return Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateX(tiltAnimation.value),
                    child: childWidget,
                  );
                },
                child: _PixelSlideTransition(
                  offset: slideAnimation,
                  child: ScaleTransition(
                    alignment: Alignment.topCenter,
                    scale: scaleAnimation,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<TaskStatus>(activeDeck),
              child: _buildActiveSheet(
                context,
                activeDeck: activeDeck,
                state: state,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ),
        ),
      ),
    ],
  );
  }

  Widget _buildActiveSheet(
    BuildContext context, {
    required TaskStatus activeDeck,
    required TaskListState state,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A))
                .withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tactile Drawer Pull Grip Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 2),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? PinTokens.darkTextTertiary
                      : PinTokens.lightTextTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Active Deck Header with swipe gestures
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) {
                  _navigateDrawer(1);
                } else if (details.primaryVelocity! > 200) {
                  _navigateDrawer(-1);
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row: e.g. "To do", "MAX 5 FOCUS", "3/5"
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  activeDeck.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // MAX 5 FOCUS pill for Today
                              if (activeDeck == TaskStatus.today)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? PinTokens.darkMaxFocusBg
                                        : PinTokens.lightMaxFocusBg,
                                    borderRadius: PinTokens.radiusFull,
                                  ),
                                  child: Text(
                                    'MAX ${state.wipLimit} FOCUS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isDark
                                          ? PinTokens.darkMaxFocusText
                                          : PinTokens.lightMaxFocusText,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Count Pill (e.g. 3/5 or 4)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? PinTokens.darkFabBg : PinTokens.lightFabBg,
                            borderRadius: PinTokens.radiusFull,
                            border: isDark
                                ? Border.all(color: PinTokens.darkBorder, width: 1.0)
                                : null,
                          ),
                          child: Text(
                            activeDeck == TaskStatus.today
                                ? '${state.todayCount}/${state.wipLimit}'
                                : (activeDeck == TaskStatus.backlog
                                    ? '${state.backlogTasks.length}'
                                    : '${state.doneTasks.length}'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? PinTokens.darkTextPrimary : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Sub-header WIP Indicator row (only on Today deck)
                    if (activeDeck == TaskStatus.today) ...[
                      Row(
                        children: [
                          // Visual Slot Pills (■ ■ ■ □ □)
                          Row(
                            children: List.generate(state.wipLimit, (index) {
                              final isFilled = index < state.todayCount;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 18,
                                height: 7,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: isFilled
                                      ? (isDark ? PinTokens.darkTextPrimary : PinTokens.lightFabBg)
                                      : (isDark
                                          ? PinTokens.darkBorder
                                          : PinTokens.lightBorder),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          const Spacer(),

                          // Available slots label
                          Text(
                            '${state.availableSlots} slots available',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? PinTokens.darkTextSecondary
                                  : PinTokens.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ] else if (activeDeck == TaskStatus.done && state.doneTasks.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          borderRadius: PinTokens.radiusSm,
                          onTap: () {
                            ref.read(taskStateProvider.notifier).clearDoneTasks();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                            child: Text(
                              'Clear Archive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PinTokens.accentRose,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Pins List in Active Deck with cascading staggered reveal
            Expanded(
              child: _buildTaskList(
                ref,
                tasks: _getTasksForDeck(state, activeDeck),
                activeDeck: activeDeck,
                isDark: isDark,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PinTask> _getTasksForDeck(TaskListState state, TaskStatus status) {
    switch (status) {
      case TaskStatus.today:
        return state.todayTasks;
      case TaskStatus.backlog:
        return state.backlogTasks;
      case TaskStatus.done:
        return state.doneTasks;
    }
  }

  Widget _buildTaskList(
    WidgetRef ref, {
    required List<PinTask> tasks,
    required TaskStatus activeDeck,
    required bool isDark,
    required Color textSecondary,
  }) {
    return _DrawerTaskList(
      key: ValueKey('drawer_tasks_${activeDeck.name}'),
      tasks: tasks,
      activeDeck: activeDeck,
      isDark: isDark,
      textSecondary: textSecondary,
    );
  }
}

/// Tactile scrollable list for the active drawer with bouncy physics and overscroll animation.
class _DrawerTaskList extends StatefulWidget {
  final List<PinTask> tasks;
  final TaskStatus activeDeck;
  final bool isDark;
  final Color textSecondary;

  const _DrawerTaskList({
    super.key,
    required this.tasks,
    required this.activeDeck,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  State<_DrawerTaskList> createState() => _DrawerTaskListState();
}

class _DrawerTaskListState extends State<_DrawerTaskList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return BouncyDrawerScrollWrapper(
        controller: _scrollController,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.activeDeck == TaskStatus.today
                              ? Icons.bolt_rounded
                              : (widget.activeDeck == TaskStatus.done
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.inventory_2_outlined),
                          size: 38,
                          color: widget.isDark
                              ? PinTokens.darkTextMuted
                              : PinTokens.lightTextTertiary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.activeDeck == TaskStatus.today
                              ? 'No active Pins today.'
                              : (widget.activeDeck == TaskStatus.done
                                  ? 'No completed Pins yet.'
                                  : 'Backlog is empty.'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.activeDeck == TaskStatus.today
                              ? 'Pin up to 5 tasks from Backlog or tap + below.'
                              : 'Tap + to capture a new Pin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? PinTokens.darkTextMuted
                                : PinTokens.lightTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return BouncyDrawerScrollWrapper(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          return _StaggeredTaskCard(
            key: ValueKey(task.id),
            index: index,
            task: task,
          );
        },
      ),
    );
  }
}

/// Cascading staggered reveal wrapper for individual task cards.
class _StaggeredTaskCard extends StatefulWidget {
  final int index;
  final PinTask task;

  const _StaggeredTaskCard({
    super.key,
    required this.index,
    required this.task,
  });

  @override
  State<_StaggeredTaskCard> createState() => _StaggeredTaskCardState();
}

class _StaggeredTaskCardState extends State<_StaggeredTaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(curve);

    final delayMs = (widget.index * 25).clamp(0, 150);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: TaskCard(
          task: widget.task,
        ),
      ),
    );
  }
}

/// Tactile interactive card for inactive stacked background tabs.
class _InactiveTabCard extends StatefulWidget {
  final TaskStatus status;
  final TaskListState state;
  final bool isDark;
  final Color borderColor;
  final Color cardBg;
  final Color? hoverBg;
  final Color textPrimary;
  final VoidCallback onTap;

  const _InactiveTabCard({
    required this.status,
    required this.state,
    required this.isDark,
    required this.borderColor,
    required this.cardBg,
    this.hoverBg,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  State<_InactiveTabCard> createState() => _InactiveTabCardState();
}

class _InactiveTabCardState extends State<_InactiveTabCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.status == TaskStatus.backlog
        ? widget.state.backlogTasks.length
        : (widget.status == TaskStatus.today
            ? widget.state.todayTasks.length
            : widget.state.doneTasks.length);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          alignment: Alignment.topCenter,
          scale: _isPressed ? 0.985 : (_isHovered ? 1.008 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.fromLTRB(18, 8, 16, 12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? (_isHovered ? const Color(0xFF1E242C) : widget.cardBg)
                  : (_isHovered ? (widget.hoverBg ?? const Color(0xFFECE7DE)) : widget.cardBg),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: _isHovered
                    ? (widget.isDark ? PinTokens.darkBorder : PinTokens.lightTextTertiary)
                    : widget.borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isDark ? Colors.black : const Color(0xFF0F172A))
                      .withValues(alpha: _isHovered ? (widget.isDark ? 0.12 : 0.07) : (widget.isDark ? 0.08 : 0.04)),
                  blurRadius: _isHovered ? 8 : 4,
                  offset: Offset(0, _isHovered ? -3 : -2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                    )),
                    child: child,
                  ),
                );
              },
              child: Row(
                key: ValueKey('${widget.status.name}_$count'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                        color: _isHovered
                            ? widget.textPrimary
                            : (widget.isDark
                                ? PinTokens.darkTextSecondary
                                : PinTokens.lightTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? PinTokens.darkCardBg
                          : PinTokens.lightTagBg,
                      borderRadius: PinTokens.radiusFull,
                      border: widget.isDark
                          ? Border.all(color: PinTokens.darkBorder, width: 1.0)
                          : null,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? PinTokens.darkTextSecondary
                            : PinTokens.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
