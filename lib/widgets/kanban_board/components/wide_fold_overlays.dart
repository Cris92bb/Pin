import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import '../../../features/ai/ui/ai_task_breakdown_modal.dart';
import '../../../features/focus_mode/ui/focus_mode_view.dart';
import '../../../features/task_crud/state/task_editor_state.dart';
import '../../../features/task_crud/ui/task_crud_modal.dart';
import '../../../shared/ui/pin_tokens.dart';

/// Overlay container displaying the FocusModeView above the inactive drawers.
class WideFoldFocusOverlay extends ConsumerWidget {
  /// The focused task.
  final PinTask task;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldFocusOverlay].
  const WideFoldFocusOverlay({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: PinTokens.shadowSlate.withValues(alpha: 0.12),
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
}

/// Overlay container displaying inline TaskCrudModal above the inactive drawers.
class WideFoldEditorOverlay extends ConsumerWidget {
  /// Arguments specifying task or initial status.
  final TaskEditorArgs args;

  /// Whether the dark theme is active.
  final bool isDark;

  /// Creates a [WideFoldEditorOverlay].
  const WideFoldEditorOverlay({
    super.key,
    required this.args,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: PinTokens.shadowSlate.withValues(alpha: 0.12),
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
