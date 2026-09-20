import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../features/task_crud/state/task_editor_state.dart';
import 'wide_fold_inactive_pane.dart';
import 'wide_fold_overlays.dart';

/// Dynamic right pane for WideFoldKanbanView switching between inactive drawers,
/// FocusMode overlay, or TaskEditor overlay.
class WideFoldRightPane extends StatelessWidget {
  /// Arguments for active inline editor if open.
  final TaskEditorArgs? activeTaskEditor;

  /// Active focus task if Focus Mode is open.
  final PinTask? activeFocusTask;

  /// Global task list state.
  final TaskListState taskState;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Inactive statuses to display when no overlay is active.
  final List<TaskStatus> inactiveStatuses;

  /// Callback when user selects an inactive status to dock to active.
  final ValueChanged<TaskStatus> onSelectStatus;

  /// Creates a [WideFoldRightPane].
  const WideFoldRightPane({
    super.key,
    required this.activeTaskEditor,
    required this.activeFocusTask,
    required this.taskState,
    required this.isDark,
    required this.inactiveStatuses,
    required this.onSelectStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
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
              curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
              reverseCurve: const Interval(0.0, 0.85, curve: Curves.easeIn),
            ),
            child: child,
          ),
        );
      },
      child: activeTaskEditor != null
          ? KeyedSubtree(
              key: const ValueKey<String>('editor_overlay'),
              child: WideFoldEditorOverlay(
                args: activeTaskEditor!,
                isDark: isDark,
              ),
            )
          : (activeFocusTask != null
              ? KeyedSubtree(
                  key: ValueKey<String>('focus_overlay_${activeFocusTask!.id}'),
                  child: WideFoldFocusOverlay(
                    task: activeFocusTask!,
                    isDark: isDark,
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey<String>('inactive_drawers'),
                  child: WideFoldInactivePane(
                    taskState: taskState,
                    isDark: isDark,
                    inactiveStatuses: inactiveStatuses,
                    onSelectStatus: onSelectStatus,
                  ),
                )),
    );
  }
}
