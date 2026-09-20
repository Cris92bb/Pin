import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../entities/task/model/atomic_step.dart';

/// Payload containing AI suggested breakdown results.
class TaskAiBreakdownPayload {
  /// Suggested title for the task.
  final String title;

  /// Suggested description, notes, or context.
  final String description;

  /// Suggested energy tag ('low-friction', 'medium-flow', 'deep-focus', etc.).
  final String energyTag;

  /// Suggested estimated minutes for the task.
  final int estimatedMinutes;

  /// Suggested categorization tags.
  final List<String> tags;

  /// Suggested sub-15m atomic steps.
  final List<AtomicStep> atomicSteps;

  /// Creates a [TaskAiBreakdownPayload].
  const TaskAiBreakdownPayload({
    required this.title,
    this.description = '',
    this.energyTag = 'medium',
    this.estimatedMinutes = 15,
    this.tags = const [],
    this.atomicSteps = const [],
  });
}

/// Handler signature for triggering AI breakdown of a prompt.
typedef TaskAiBreakdownHandler = Future<TaskAiBreakdownPayload?> Function(
  BuildContext context,
  WidgetRef ref, {
  required String prompt,
  String? currentDescription,
});
