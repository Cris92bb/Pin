import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';
import '../../../entities/task/state/task_state_notifier.dart';
import 'task_crud_types.dart';

/// Helper handling Pin creation, updating, and AI breakdown logic for TaskCrudModal.
class TaskCrudActions {
  /// Executes AI prompt decomposition via the configured handler.
  static Future<TaskAiBreakdownPayload?> executeAiBreakdown({
    required BuildContext context,
    required WidgetRef ref,
    required TaskAiBreakdownHandler? handler,
    required String prompt,
    required String currentDescription,
    required ValueChanged<String> onError,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      onError('Please enter a task title or idea first so Gemini can analyze it.');
      return null;
    }
    if (handler == null) {
      onError('AI Breakdown handler is not configured.');
      return null;
    }

    try {
      final desc = currentDescription.trim();
      return await handler(
        context,
        ref,
        prompt: cleanPrompt,
        currentDescription: desc.isNotEmpty ? desc : null,
      );
    } catch (e) {
      onError(e.toString());
      return null;
    }
  }

  /// Executes the task submission (create or update) and returns true on success.
  static Future<bool> executeSubmit({
    required WidgetRef ref,
    required PinTask? initialTask,
    required String title,
    required String description,
    required TaskStatus selectedStatus,
    required String selectedEnergyTag,
    required int selectedEstimateMinutes,
    required List<String> tags,
    required List<AtomicStep> subtasks,
    required ValueChanged<String> onError,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      onError('Please enter a Pin title.');
      return false;
    }

    final notifier = ref.read(taskStateProvider.notifier);
    final now = DateTime.now();

    if (initialTask == null) {
      final newTask = PinTask(
        id: 'pin_${now.microsecondsSinceEpoch}',
        title: cleanTitle,
        description: description.trim(),
        status: selectedStatus,
        isPinned: selectedStatus == TaskStatus.today,
        energyTag: selectedEnergyTag,
        estimatedMinutes: selectedEstimateMinutes,
        tags: tags,
        trackedSeconds: 0,
        subtasks: subtasks,
        createdAt: now,
        updatedAt: now,
      );

      final success = await notifier.createTask(newTask);
      if (success) {
        ref.read(activeDeckProvider.notifier).state = selectedStatus;
        return true;
      } else {
        final state = ref.read(taskStateProvider);
        onError(state.alertMessage ?? 'WIP limit reached!');
        return false;
      }
    } else {
      final updated = initialTask.copyWith(
        title: cleanTitle,
        description: description.trim(),
        status: selectedStatus,
        isPinned: selectedStatus == TaskStatus.today,
        energyTag: selectedEnergyTag,
        estimatedMinutes: selectedEstimateMinutes,
        tags: tags,
        subtasks: subtasks,
        updatedAt: now,
      );

      final success = await notifier.updateTask(updated);
      if (success) {
        final currentFocus = ref.read(activeFocusTaskProvider);
        if (currentFocus?.id == updated.id) {
          ref.read(activeFocusTaskProvider.notifier).state = updated;
        }
        ref.read(activeDeckProvider.notifier).state = selectedStatus;
        return true;
      } else {
        final state = ref.read(taskStateProvider);
        onError(state.alertMessage ?? 'WIP limit reached!');
        return false;
      }
    }
  }
}
