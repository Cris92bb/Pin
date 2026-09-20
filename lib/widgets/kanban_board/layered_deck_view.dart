import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../shared/ui/pin_tokens.dart';
import 'components/layered_deck_active_sheet.dart';
import 'components/layered_deck_inactive_tab.dart';
import 'components/layered_deck_transitions.dart';

/// Layered Card Deck Kanban View matching the companion app design.
///
/// Drawers/Columns are rendered as a tactile stack of physical index cards / sheets
/// with fluid Apple-spring 3D perspective transitions between drawers, cascading card
/// reveals, tactile drawer pull grips, interactive tabs, and swipe gestures.
class LayeredDeckView extends ConsumerStatefulWidget {
  /// Creates a [LayeredDeckView].
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
    final inactiveTabs =
        allTabs.where((status) => status != activeDeck).toList();

    // Compute exact vertical origin of newly active deck directly from its tab slot
    double targetYOffset = -72.0;
    if (activeDeck != _currentDeck) {
      final prevInactiveTabs =
          allTabs.where((status) => status != _currentDeck).toList();
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
          child: LayeredDeckInactiveTab(
            status: inactiveTabs[0],
            state: state,
            isDark: isDark,
            borderColor: borderColor,
            cardBg: isDark
                ? PinTokens.darkStackedTabBg
                : PinTokens.lightStackedTabBg,
            hoverBg: isDark
                ? PinTokens.darkSurfaceHover
                : PinTokens.lightSurfaceHover,
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
          child: LayeredDeckInactiveTab(
            status: inactiveTabs[1],
            state: state,
            isDark: isDark,
            borderColor: borderColor,
            cardBg: isDark
                ? PinTokens.darkStackedTabBg
                : PinTokens.lightStackedTabBg,
            hoverBg: isDark
                ? PinTokens.darkSurfaceHover
                : PinTokens.lightSurfaceHover,
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
                // Fluid ease-in-out curve for natural physical drawer motion
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                  reverseCurve: Curves.easeInOutCubic,
                );

                // Exact pixel slide matching the clicked tab's slot:
                final slideAnimation = Tween<Offset>(
                  begin: Offset(0.0, targetYOffset),
                  end: Offset.zero,
                ).animate(curved);

                // Tactile scale transition:
                final scaleAnimation = Tween<double>(
                  begin: 0.88,
                  end: 1.0,
                ).animate(curved);

                // Synchronized opacity fade:
                final fadeAnimation = CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.70, curve: Curves.easeInOut),
                  reverseCurve:
                      const Interval(0.30, 1.0, curve: Curves.easeInOut),
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
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(tiltAnimation.value),
                      child: childWidget,
                    );
                  },
                  child: PixelSlideTransition(
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
                child: LayeredDeckActiveSheet(
                  activeDeck: activeDeck,
                  state: state,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onNavigateDrawer: _navigateDrawer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
