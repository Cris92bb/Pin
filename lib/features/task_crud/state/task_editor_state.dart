import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_providers.dart';

/// Configuration arguments for the active task editor overlay in wide/fold mode.
class TaskEditorArgs {
  final PinTask? task;
  final TaskStatus? defaultStatus;
  final bool autoTriggerAi;

  const TaskEditorArgs({
    this.task,
    this.defaultStatus,
    this.autoTriggerAi = false,
  });
}

/// Holds the currently open inline task editor in wide/fold mode (null if closed).
final activeTaskEditorProvider =
    NotifierProvider<StateValueNotifier<TaskEditorArgs?>, TaskEditorArgs?>(
  () => StateValueNotifier(() => null),
);
