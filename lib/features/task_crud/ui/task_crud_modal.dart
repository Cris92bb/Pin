import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'task_crud_action_buttons.dart';
import 'task_crud_actions.dart';
import 'task_crud_container.dart';
import 'task_crud_form_body.dart';
import 'task_crud_header.dart';
import 'task_crud_types.dart';

export 'task_crud_types.dart';

/// Modal dialog for creating or editing Pins with tags, estimation chips, and energy states.
class TaskCrudModal extends ConsumerStatefulWidget {
  /// Default global handler for Gemini AI breakdown.
  static TaskAiBreakdownHandler? defaultAiBreakdownHandler;

  /// Default global handler for opening AI settings.
  static void Function(BuildContext context)? defaultAiSettingsHandler;

  /// Default global handler for sharing a Pin.
  static void Function(BuildContext context, PinTask task)? defaultShareHandler;

  /// Optional initial task for editing mode.
  final PinTask? initialTask;
  final TaskStatus? defaultStatus;
  final bool autoTriggerAi;
  final bool asDialog;
  final VoidCallback? onClose;
  final TaskAiBreakdownHandler? onAiBreakdown;
  final VoidCallback? onOpenAiSettings;
  final VoidCallback? onShare;

  const TaskCrudModal({
    super.key,
    this.initialTask,
    this.defaultStatus,
    this.autoTriggerAi = false,
    this.asDialog = true,
    this.onClose,
    this.onAiBreakdown,
    this.onOpenAiSettings,
    this.onShare,
  });

  /// Displays the modal dialog.
  static Future<void> show(
    BuildContext context, {
    PinTask? task,
    TaskStatus? defaultStatus,
    bool autoTriggerAi = false,
    TaskAiBreakdownHandler? onAiBreakdown,
    VoidCallback? onOpenAiSettings,
    VoidCallback? onShare,
  }) =>
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => TaskCrudModal(
          initialTask: task,
          defaultStatus: defaultStatus,
          autoTriggerAi: autoTriggerAi,
          onAiBreakdown: onAiBreakdown,
          onOpenAiSettings: onOpenAiSettings,
          onShare: onShare,
        ),
      );

  @override
  ConsumerState<TaskCrudModal> createState() => _TaskCrudModalState();
}

class _TaskCrudModalState extends ConsumerState<TaskCrudModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _subtaskController;
  late final TextEditingController _tagController;

  late TaskStatus _selectedStatus;
  late String _selectedEnergyTag;
  late int _selectedEstimateMinutes;
  late List<String> _tags;
  late List<AtomicStep> _subtasks;
  String? _inlineError;
  bool _isGeneratingWithAi = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _subtaskController = TextEditingController();
    _tagController = TextEditingController();

    final taskState = ref.read(taskStateProvider);
    final fallbackStatus =
        taskState.isTodayWipFull ? TaskStatus.backlog : TaskStatus.today;
    _selectedStatus = task?.status ?? widget.defaultStatus ?? fallbackStatus;
    if (task == null &&
        _selectedStatus == TaskStatus.today &&
        taskState.isTodayWipFull &&
        widget.defaultStatus == null) {
      _selectedStatus = TaskStatus.backlog;
    }
    _selectedEnergyTag = task?.energyTag ?? 'low-friction';
    _selectedEstimateMinutes = task?.estimatedMinutes ?? 15;
    _tags = task?.tags != null ? List.from(task!.tags) : ['#dev'];
    _subtasks = task?.subtasks != null ? List.from(task!.subtasks) : [];

    if (widget.autoTriggerAi) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generateTaskWithAi();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(AtomicStep(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: text,
        isCompleted: false,
        estimatedMinutes: 15,
      ));
      _subtaskController.clear();
    });
  }

  Future<void> _generateTaskWithAi() async {
    setState(() {
      _isGeneratingWithAi = true;
      _inlineError = null;
    });

    final breakdown = await TaskCrudActions.executeAiBreakdown(
      context: context,
      ref: ref,
      handler: widget.onAiBreakdown ?? TaskCrudModal.defaultAiBreakdownHandler,
      prompt: _titleController.text,
      currentDescription: _descController.text,
      onError: (err) {
        if (mounted) setState(() => _inlineError = err);
      },
    );

    if (mounted) {
      setState(() => _isGeneratingWithAi = false);
      if (breakdown != null) {
        setState(() {
          _titleController.text = breakdown.title;
          if (breakdown.description.isNotEmpty) {
            _descController.text = breakdown.description;
          }
          _selectedEnergyTag = breakdown.energyTag;
          _selectedEstimateMinutes = breakdown.estimatedMinutes;
          _tags = List.from(breakdown.tags);
          _subtasks = List.from(breakdown.atomicSteps);
          _inlineError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Gemini decomposed this into ${breakdown.atomicSteps.length} atomic steps and filled all properties!',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _dismiss() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    final success = await TaskCrudActions.executeSubmit(
      ref: ref,
      initialTask: widget.initialTask,
      title: _titleController.text,
      description: _descController.text,
      selectedStatus: _selectedStatus,
      selectedEnergyTag: _selectedEnergyTag,
      selectedEstimateMinutes: _selectedEstimateMinutes,
      tags: _tags,
      subtasks: _subtasks,
      onError: (err) {
        if (mounted) setState(() => _inlineError = err);
      },
    );
    if (success && mounted) {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    final taskState = ref.watch(taskStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TaskCrudContainer(
      asDialog: widget.asDialog,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskCrudHeader(
              isEditing: isEditing,
              isDark: isDark,
              onOpenAiSettings: () {
                if (widget.onOpenAiSettings != null) {
                  widget.onOpenAiSettings!();
                } else {
                  TaskCrudModal.defaultAiSettingsHandler?.call(context);
                }
              },
              onShare: widget.initialTask == null
                  ? null
                  : () {
                      if (widget.onShare != null) {
                        widget.onShare!();
                      } else {
                        TaskCrudModal.defaultShareHandler
                            ?.call(context, widget.initialTask!);
                      }
                    },
              onClose: _dismiss,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TaskCrudFormBody(
                titleController: _titleController,
                descController: _descController,
                tagController: _tagController,
                subtaskController: _subtaskController,
                inlineError: _inlineError,
                isGeneratingWithAi: _isGeneratingWithAi,
                isEditing: isEditing,
                isDark: isDark,
                selectedStatus: _selectedStatus,
                taskState: taskState,
                initialStatus: widget.initialTask?.status,
                tags: _tags,
                selectedEstimateMinutes: _selectedEstimateMinutes,
                selectedEnergyTag: _selectedEnergyTag,
                subtasks: _subtasks,
                onSubmit: _submit,
                onAiGenerate: _generateTaskWithAi,
                onStatusSelected: (s) => setState(() => _selectedStatus = s),
                onAddTag: (tag) {
                  final clean = tag.startsWith('#') ? tag : '#$tag';
                  if (!_tags.contains(clean)) setState(() => _tags.add(clean));
                  _tagController.clear();
                },
                onRemoveTag: (tag) => setState(() => _tags.remove(tag)),
                onEstimateChanged: (m) => setState(() => _selectedEstimateMinutes = m),
                onEnergyChanged: (t) => setState(() => _selectedEnergyTag = t),
                onAddSubtask: _addSubtask,
                onToggleStep: (idx, val) => setState(() {
                  _subtasks[idx] = _subtasks[idx].copyWith(isCompleted: val);
                }),
                onDeleteStep: (idx) => setState(() => _subtasks.removeAt(idx)),
              ),
            ),
            const SizedBox(height: 16),
            TaskCrudActionButtons(
              isEditing: isEditing,
              onCancel: _dismiss,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
