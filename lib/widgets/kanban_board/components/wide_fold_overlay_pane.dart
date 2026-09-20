import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../features/task_crud/state/task_editor_state.dart';
import 'wide_fold_overlays.dart';

/// Animated overlay panel for Focus Mode and Task Editor on wide/fold screens.
///
/// Positioned above the inactive drawers section, smoothly transitioning
/// in and out without hiding or displacing the persistent active queue beside it.
class WideFoldOverlayPane extends StatelessWidget {
  /// Arguments for active inline editor if open.
  final TaskEditorArgs? activeTaskEditor;

  /// Active focus task if Focus Mode is open.
  final PinTask? activeFocusTask;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldOverlayPane].
  const WideFoldOverlayPane({
    super.key,
    required this.activeTaskEditor,
    required this.activeFocusTask,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverlay = activeTaskEditor != null || activeFocusTask != null;

    final Widget content;
    if (activeTaskEditor != null) {
      content = KeyedSubtree(
        key: const ValueKey<String>('editor_overlay'),
        child: WideFoldEditorOverlay(
          args: activeTaskEditor!,
          isDark: isDark,
        ),
      );
    } else if (activeFocusTask != null) {
      content = KeyedSubtree(
        key: ValueKey<String>('focus_overlay_${activeFocusTask!.id}'),
        child: WideFoldFocusOverlay(
          task: activeFocusTask!,
          isDark: isDark,
        ),
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey<String>('no_overlay'));
    }

    return IgnorePointer(
      ignoring: !hasOverlay,
      child: AnimatedSwitcher(
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
        child: content,
      ),
    );
  }
}
