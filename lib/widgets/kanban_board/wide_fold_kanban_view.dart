import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../entities/task/model/pin_task.dart';
import '../../entities/task/state/task_state_notifier.dart';
import '../../features/task_crud/state/task_editor_state.dart';
import 'components/wide_fold_active_pane.dart';
import 'components/wide_fold_right_pane.dart';

/// Responsive 3-drawer Kanban layout optimized for Web, Foldable devices, and wide screens.
///
/// Displays 3 drawers (Backlog, Today, Done):
/// - The focused/active drawer is wider (in primary section, flex 3) with 100% opacity.
/// - The 2 inactive drawers are displayed side-by-side with subtle opacity (flex 5).
/// - Tapping an inactive drawer smoothly glides from its position on the right across to the
///   active position on the left, expanding into full width, while the active drawer glides
///   into the vacated slot and docks cleanly.
/// - When entering Focus Mode or creating/editing a task, the overlay panel slides
///   over the 2 inactive drawers, keeping the active queue visible beside it.
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

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Left Pane: Persistent Active Column (flex: 3) ───
          Expanded(
            flex: 3,
            child: WideFoldActivePane(
              transitionCurve: _transitionCurve,
              isAnimating: _transitionController.isAnimating,
              activeStatus: _activeStatus,
              departingStatus: _departingStatus,
              arrivingStatus: _arrivingStatus,
              taskState: taskState,
              isDark: isDark,
              scrollController: _activeScrollController,
            ),
          ),

          const SizedBox(width: 14),

          // ─── Right Pane: Dynamic Content (flex: 5) ───
          Expanded(
            flex: 5,
            child: WideFoldRightPane(
              activeTaskEditor: activeTaskEditor,
              activeFocusTask: activeFocusTask,
              taskState: taskState,
              isDark: isDark,
              inactiveStatuses: inactiveStatuses,
              onSelectStatus: _selectInactiveDrawer,
            ),
          ),
        ],
      ),
    );
  }
}
