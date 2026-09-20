import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../shared/ui/pin_tokens.dart';
import 'wide_fold_active_drawer.dart';

/// The active pane on the left side of WideFoldKanbanView with swap transition animation.
class WideFoldActivePane extends StatelessWidget {
  /// Curved animation driven by transition controller.
  final Animation<double> transitionCurve;

  /// Whether transition animation is in progress.
  final bool isAnimating;

  /// Currently active status.
  final TaskStatus activeStatus;

  /// Departing status during transition.
  final TaskStatus? departingStatus;

  /// Arriving status during transition.
  final TaskStatus? arrivingStatus;

  /// Global task list state.
  final TaskListState taskState;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Scroll controller for active drawer.
  final ScrollController scrollController;

  /// Creates a [WideFoldActivePane].
  const WideFoldActivePane({
    super.key,
    required this.transitionCurve,
    required this.isAnimating,
    required this.activeStatus,
    this.departingStatus,
    this.arrivingStatus,
    required this.taskState,
    required this.isDark,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: transitionCurve,
      builder: (context, _) {
        final animating = isAnimating || arrivingStatus != null;
        final t = transitionCurve.value;

        if (!animating) {
          return WideFoldActiveDrawer(
            status: activeStatus,
            taskState: taskState,
            isDark: isDark,
            scrollController: scrollController,
          );
        }

        // During swap: stack departing (fading out) and arriving (sliding in)
        return Stack(
          fit: StackFit.expand,
          children: [
            // Departing drawer (shrinks and fades out to the right)
            if (departingStatus != null)
              Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(40.0 * t, 0),
                  child: WideFoldActiveDrawer(
                    status: departingStatus!,
                    taskState: taskState,
                    isDark: isDark,
                    scrollController: scrollController,
                  ),
                ),
              ),

            // Arriving drawer (slides in from the right with elevation)
            if (arrivingStatus != null)
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
                                  : PinTokens.shadowSlate)
                              .withValues(alpha: 0.25 * (1.0 - t)),
                          blurRadius: 20,
                          offset: const Offset(-6, 8),
                        ),
                      ],
                    ),
                    child: WideFoldActiveDrawer(
                      status: arrivingStatus!,
                      taskState: taskState,
                      isDark: isDark,
                      scrollController: scrollController,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
