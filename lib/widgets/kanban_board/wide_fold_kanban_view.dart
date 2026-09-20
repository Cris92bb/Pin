import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/task_crud/state/task_editor_state.dart';
import 'components/wide_fold_overlay_pane.dart';
import 'components/wide_fold_swap_layer.dart';

/// Responsive 3-drawer Kanban layout optimized for Web, Foldable devices, and wide screens.
///
/// Architecture & Behavioral Mechanics:
/// - Layer: `widgets/kanban_board` (Feature-Sliced Design v2.1)
/// - Displays 3 drawers (Backlog, Today, Done):
///   - The focused/active drawer is wider (in primary section, flex 4 of 10) with full controls.
///   - The 2 inactive drawers are displayed side-by-side with subtle opacity (flex 6 of 10).
/// - Tactile Physical Transitions:
///   - Tapping an inactive drawer triggers a smooth cross-screen physical slide replacement:
///     the tapped inactive drawer glides across the gap from its right slot to the left column,
///     elevated with drop shadows, while the departing active drawer glides into the vacated slot
///     where a soft docking tray provides visual feedback.
///   - The untouched inactive drawer remains rock-solid in place.
/// - Master-Detail Overlays:
///   - When entering Focus Mode or creating/editing a task, the overlay panel slides
///     over the 2 inactive drawers via [WideFoldOverlayPane], keeping the active queue visible beside it.
class WideFoldKanbanView extends ConsumerStatefulWidget {
  /// Creates a [WideFoldKanbanView].
  const WideFoldKanbanView({super.key});

  @override
  ConsumerState<WideFoldKanbanView> createState() => _WideFoldKanbanViewState();
}

class _WideFoldKanbanViewState extends ConsumerState<WideFoldKanbanView>
    with SingleTickerProviderStateMixin {
  final ScrollController _activeScrollController = ScrollController();

  late final AnimationController _transitionController;
  late final CurvedAnimation _transitionCurve;

  TaskStatus _activeStatus = TaskStatus.today;
  TaskStatus? _departingStatus;
  TaskStatus? _arrivingStatus;
  int _swappingSlotIndex = 0;

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

  void _selectInactiveDrawer(TaskStatus status, int slotIndex) {
    if (_transitionController.isAnimating) return;
    ref.read(activeDeckProvider.notifier).state = status;
    _startDrawerTransition(status, slotIndex);
  }

  void _startDrawerTransition(TaskStatus newActiveStatus,
      [int? preferredSlotIndex]) {
    if (newActiveStatus == _activeStatus) return;
    const allStatuses = [TaskStatus.backlog, TaskStatus.today, TaskStatus.done];
    final currentInactive =
        allStatuses.where((s) => s != _activeStatus).toList();
    final slotIdx =
        preferredSlotIndex ?? currentInactive.indexOf(newActiveStatus);
    if (slotIdx == -1) {
      setState(() => _activeStatus = newActiveStatus);
      return;
    }

    _transitionController.value = 0.0;
    setState(() {
      _departingStatus = _activeStatus;
      _arrivingStatus = newActiveStatus;
      _swappingSlotIndex = slotIdx;
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

  @override
  Widget build(BuildContext context) {
    ref.listen<TaskListState>(taskStateProvider, (previous, next) {
      final currentFocus = ref.read(activeFocusTaskProvider);
      if (currentFocus != null) {
        final matching =
            next.tasks.where((t) => t.id == currentFocus.id).firstOrNull;
        if (matching == null || matching.status == TaskStatus.done) {
          ref.read(activeFocusTaskProvider.notifier).state = null;
        } else if (matching != currentFocus) {
          ref.read(activeFocusTaskProvider.notifier).state = matching;
        }
      }
    });

    final taskState = ref.watch(taskStateProvider);
    final activeDeck = ref.watch(activeDeckProvider);
    final activeFocusTask = ref.watch(activeFocusTaskProvider);
    final activeTaskEditor = ref.watch(activeTaskEditorProvider);

    // Keep _activeStatus in sync if activeDeckProvider was changed externally while idle
    if (activeDeck != _activeStatus &&
        _arrivingStatus == null &&
        !_transitionController.isAnimating) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          const gap = 14.0;

          // Flex allocation: flex 4 for active column, flex 6 for inactive section
          final flexUnit = (availableWidth - gap) / 10.0;
          final activeWidth = flexUnit * 4.0;
          final inactiveSectionWidth = flexUnit * 6.0;
          final inactiveCardWidth = (inactiveSectionWidth - gap) / 2.0;

          final slot0Left = activeWidth + gap;
          final slot1Left = activeWidth + 2 * gap + inactiveCardWidth;

          return AnimatedBuilder(
            animation: _transitionCurve,
            builder: (context, _) {
              final isAnimating =
                  _transitionController.isAnimating || _arrivingStatus != null;
              final t = _transitionCurve.value;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Core 3-drawer layout & physical swap gliding layer
                  Positioned.fill(
                    child: WideFoldSwapLayer(
                      progress: t,
                      isAnimating: isAnimating,
                      activeWidth: activeWidth,
                      inactiveCardWidth: inactiveCardWidth,
                      slot0Left: slot0Left,
                      slot1Left: slot1Left,
                      swappingSlotIndex: _swappingSlotIndex,
                      activeStatus: _activeStatus,
                      departingStatus: _departingStatus,
                      arrivingStatus: _arrivingStatus,
                      inactiveStatuses: inactiveStatuses,
                      taskState: taskState,
                      isDark: isDark,
                      scrollController: _activeScrollController,
                      onSelectSlot: _selectInactiveDrawer,
                    ),
                  ),

                  // 2. Overlay Panel for Focus Mode or Task Editor (placed above inactive section)
                  Positioned(
                    left: activeWidth + gap,
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: WideFoldOverlayPane(
                      activeTaskEditor: activeTaskEditor,
                      activeFocusTask: activeFocusTask,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
