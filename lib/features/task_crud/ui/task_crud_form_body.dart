import 'package:flutter/material.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'task_crud_ai_button.dart';
import 'task_crud_deck_selector.dart';
import 'task_crud_form_fields.dart';
import 'task_crud_scope_selectors.dart';
import 'task_crud_subtasks_section.dart';
import 'task_crud_tags_section.dart';

/// Form body containing all input fields, AI trigger, selectors, and subtasks list.
class TaskCrudFormBody extends StatelessWidget {
  /// Controller for title.
  final TextEditingController titleController;

  /// Controller for description.
  final TextEditingController descController;

  /// Controller for tag input.
  final TextEditingController tagController;

  /// Controller for subtask input.
  final TextEditingController subtaskController;

  /// Optional inline error message.
  final String? inlineError;

  /// Whether AI breakdown is in flight.
  final bool isGeneratingWithAi;

  /// Whether editing an existing task.
  final bool isEditing;

  /// Whether dark theme is active.
  final bool isDark;

  /// Selected status.
  final TaskStatus selectedStatus;

  /// Global task state.
  final TaskListState taskState;

  /// Initial status if editing.
  final TaskStatus? initialStatus;

  /// Assigned tags.
  final List<String> tags;

  /// Quick tag suggestions.
  final List<String> quickTags;

  /// Selected duration in minutes.
  final int selectedEstimateMinutes;

  /// Selected energy tag string.
  final String selectedEnergyTag;

  /// Subtasks list.
  final List<AtomicStep> subtasks;

  /// Callback when submitting via title field.
  final VoidCallback onSubmit;

  /// Callback when AI generation is triggered.
  final VoidCallback onAiGenerate;

  /// Callback when status is selected.
  final ValueChanged<TaskStatus> onStatusSelected;

  /// Callback when adding a tag.
  final ValueChanged<String> onAddTag;

  /// Callback when removing a tag.
  final ValueChanged<String> onRemoveTag;

  /// Callback when estimate duration is changed.
  final ValueChanged<int> onEstimateChanged;

  /// Callback when energy tag is changed.
  final ValueChanged<String> onEnergyChanged;

  /// Callback when adding a subtask.
  final VoidCallback onAddSubtask;

  /// Callback when toggling subtask completion.
  final void Function(int index, bool isCompleted) onToggleStep;

  /// Callback when deleting a subtask.
  final ValueChanged<int> onDeleteStep;

  /// Creates a [TaskCrudFormBody].
  const TaskCrudFormBody({
    super.key,
    required this.titleController,
    required this.descController,
    required this.tagController,
    required this.subtaskController,
    this.inlineError,
    required this.isGeneratingWithAi,
    required this.isEditing,
    required this.isDark,
    required this.selectedStatus,
    required this.taskState,
    this.initialStatus,
    required this.tags,
    this.quickTags = TaskCrudTagsSection.defaultQuickTags,
    required this.selectedEstimateMinutes,
    required this.selectedEnergyTag,
    required this.subtasks,
    required this.onSubmit,
    required this.onAiGenerate,
    required this.onStatusSelected,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onEstimateChanged,
    required this.onEnergyChanged,
    required this.onAddSubtask,
    required this.onToggleStep,
    required this.onDeleteStep,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskCrudFormFields(
            titleController: titleController,
            descController: descController,
            inlineError: inlineError,
            onSubmit: onSubmit,
            middleWidget: TaskCrudAiButton(
              isGeneratingWithAi: isGeneratingWithAi,
              isEditing: isEditing,
              isDark: isDark,
              onTap: onAiGenerate,
            ),
          ),
          const SizedBox(height: 16),
          TaskCrudDeckSelector(
            selectedStatus: selectedStatus,
            taskState: taskState,
            isEditing: isEditing,
            initialStatus: initialStatus,
            onStatusSelected: onStatusSelected,
          ),
          const SizedBox(height: 16),
          TaskCrudTagsSection(
            tags: tags,
            quickTags: quickTags,
            tagController: tagController,
            onAddTag: onAddTag,
            onRemoveTag: onRemoveTag,
          ),
          const SizedBox(height: 16),
          TaskCrudScopeSelectors(
            selectedEstimateMinutes: selectedEstimateMinutes,
            selectedEnergyTag: selectedEnergyTag,
            onEstimateChanged: onEstimateChanged,
            onEnergyChanged: onEnergyChanged,
          ),
          const SizedBox(height: 18),
          TaskCrudSubtasksSection(
            subtasks: subtasks,
            subtaskController: subtaskController,
            onAddSubtask: onAddSubtask,
            onToggleStep: onToggleStep,
            onDeleteStep: onDeleteStep,
          ),
        ],
      ),
    );
  }
}
