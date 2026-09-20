import 'package:flutter/material.dart';
import '../../../entities/task/model/pin_task.dart';
import 'focus_mode_hero_section.dart';
import 'focus_mode_sticky_banner.dart';
import 'focus_mode_subtasks_section.dart';
import 'focus_mode_top_bar.dart';

/// Full interactive body layout for FocusModeView.
class FocusModeBody extends StatelessWidget {
  /// The task currently focused.
  final PinTask task;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Controller for the main scrollable area.
  final ScrollController scrollController;

  /// Controller for the micro-step text field.
  final TextEditingController stepController;

  /// Total elapsed seconds including prior sessions.
  final int totalElapsedSeconds;

  /// Seconds in current running session.
  final int sessionSeconds;

  /// Whether the session timer is running.
  final bool isRunning;

  /// Whether the user has scrolled past the big timer.
  final bool isScrolledPastTimer;

  /// Callback to exit focus mode.
  final VoidCallback onExit;

  /// Callback to reanalyze task with AI.
  final VoidCallback onReanalyzeWithAi;

  /// Callback to edit task.
  final VoidCallback onEditTask;

  /// Callback to complete task.
  final VoidCallback onCompleteTask;

  /// Callback to toggle pause/resume on timer.
  final VoidCallback onToggleTimer;

  /// Callback to reset session timer.
  final VoidCallback onResetTimer;

  /// Callback when a step checkbox is toggled.
  final void Function(int index, bool checked) onToggleStep;

  /// Callback when a step is deleted.
  final void Function(int index) onDeleteStep;

  /// Callback when adding a new step.
  final VoidCallback onAddNewStep;

  /// Creates a [FocusModeBody].
  const FocusModeBody({
    super.key,
    required this.task,
    required this.isDark,
    required this.scrollController,
    required this.stepController,
    required this.totalElapsedSeconds,
    required this.sessionSeconds,
    required this.isRunning,
    required this.isScrolledPastTimer,
    required this.onExit,
    required this.onReanalyzeWithAi,
    required this.onEditTask,
    required this.onCompleteTask,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onToggleStep,
    required this.onDeleteStep,
    required this.onAddNewStep,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 780;
        final isVeryNarrow = constraints.maxWidth < 360;

        return Column(
          children: [
            FocusModeTopBar(
              isDark: isDark,
              isNarrow: isNarrow,
              isVeryNarrow: isVeryNarrow,
              onExit: onExit,
              onReanalyzeWithAi: onReanalyzeWithAi,
              onEditTask: onEditTask,
              onCompleteTask: onCompleteTask,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: isScrolledPastTimer
                  ? FocusModeStickyBanner(
                      isDark: isDark,
                      totalElapsedSeconds: totalElapsedSeconds,
                      isRunning: isRunning,
                      onToggleTimer: onToggleTimer,
                      onResetTimer: onResetTimer,
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    FocusModeHeroSection(
                      task: task,
                      isDark: isDark,
                      isNarrow: isNarrow,
                      totalElapsedSeconds: totalElapsedSeconds,
                      sessionSeconds: sessionSeconds,
                      isRunning: isRunning,
                      onToggleTimer: onToggleTimer,
                      onResetTimer: onResetTimer,
                    ),
                    FocusModeSubtasksSection(
                      task: task,
                      isDark: isDark,
                      isNarrow: isNarrow,
                      constraints: constraints,
                      stepController: stepController,
                      onToggleStep: onToggleStep,
                      onDeleteStep: onDeleteStep,
                      onAddNewStep: onAddNewStep,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
