import '../../../entities/task/model/atomic_step.dart';
import '../../../entities/task/model/pin_task.dart';

/// Formatter and smart text parser for sharing and importing Pin tasks.
///
/// Converts tasks to and from human-readable Markdown notes, checklists,
/// and plain text summaries for easy clipboard sharing into external apps.
class TaskTextFormatter {
  /// Formats a single [PinTask] into a clean Markdown note.
  static String formatSingleTask(PinTask task) {
    final buffer = StringBuffer();
    buffer.writeln('📌 ${task.title}');

    final meta = <String>[];
    meta.add('Status: ${task.status.label}');
    meta.add('${task.energyEmoji} ${task.energyDisplayLabel}');
    meta.add('⏱️ ${task.estimatedMinutes}m');
    if (task.tags.isNotEmpty) {
      meta.add('🏷️ ${task.tags.join(' ')}');
    }
    buffer.writeln(meta.join(' • '));

    if (task.description.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(task.description.trim());
    }

    if (task.subtasks.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Subtasks:');
      for (final step in task.subtasks) {
        final mark = step.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('- $mark ${step.title}');
      }
    }

    return buffer.toString().trim();
  }

  /// Formats a list of [PinTask]s into a structured Markdown document.
  ///
  /// If [groupByStatus] is true, items are grouped under Today, Backlog, and Done sections.
  static String formatTaskList(
    List<PinTask> tasks, {
    String? headerTitle,
    bool groupByStatus = true,
  }) {
    if (tasks.isEmpty) {
      return 'No tasks to export.';
    }

    final buffer = StringBuffer();
    final title = headerTitle ?? '📌 Pin Tasks Export';
    buffer.writeln('# $title');
    buffer.writeln('Exported on ${DateTime.now().toLocal().toString().split('.').first}');
    buffer.writeln();

    if (!groupByStatus) {
      for (final task in tasks) {
        buffer.writeln(formatSingleTask(task));
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
      return buffer.toString().trim();
    }

    final todayTasks = tasks.where((t) => t.status == TaskStatus.today).toList();
    final backlogTasks = tasks.where((t) => t.status == TaskStatus.backlog).toList();
    final doneTasks = tasks.where((t) => t.status == TaskStatus.done).toList();

    if (todayTasks.isNotEmpty) {
      buffer.writeln('## ⚡ Today (${todayTasks.length})');
      for (final task in todayTasks) {
        _writeTaskBullet(buffer, task);
      }
      buffer.writeln();
    }

    if (backlogTasks.isNotEmpty) {
      buffer.writeln('## 📋 Backlog (${backlogTasks.length})');
      for (final task in backlogTasks) {
        _writeTaskBullet(buffer, task);
      }
      buffer.writeln();
    }

    if (doneTasks.isNotEmpty) {
      buffer.writeln('## ✅ Done (${doneTasks.length})');
      for (final task in doneTasks) {
        _writeTaskBullet(buffer, task);
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  static void _writeTaskBullet(StringBuffer buffer, PinTask task) {
    final check = task.status == TaskStatus.done ? '[x]' : '[ ]';
    final tagStr = task.tags.isNotEmpty ? ' ${task.tags.join(' ')}' : '';
    buffer.writeln('- $check ${task.title} (${task.estimatedMinutes}m)$tagStr');

    if (task.description.trim().isNotEmpty) {
      buffer.writeln('  > ${task.description.trim()}');
    }

    for (final step in task.subtasks) {
      final stepCheck = step.isCompleted ? '[x]' : '[ ]';
      buffer.writeln('  - $stepCheck ${step.title}');
    }
  }

  /// Parses plain text or markdown lists into [PinTask] models.
  ///
  /// Understands markdown checkboxes (`- [ ]`), bullet points (`*`, `-`),
  /// numbered lists, hashtags (`#work`), and duration notations like `(30m)`.
  static List<PinTask> parseTextToTasks(
    String input, {
    TaskStatus defaultStatus = TaskStatus.backlog,
  }) {
    final lines = input.split('\n');
    final tasks = <PinTask>[];
    PinTask? currentTask;
    final currentSubtasks = <AtomicStep>[];

    void commitCurrentTask() {
      if (currentTask != null) {
        tasks.add(currentTask!.copyWith(subtasks: List.from(currentSubtasks)));
        currentSubtasks.clear();
        currentTask = null;
      }
    }

    final durationRegex = RegExp(r'\((\d+)\s*(?:m|min|mins|minutes)?\)', caseSensitive: false);
    final tagRegex = RegExp(r'#([A-Za-z0-9_-]+)');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Check if line is indented, indicating a subtask for current task
      final isIndented = rawLine.startsWith('  ') || rawLine.startsWith('\t');

      if (isIndented && currentTask != null) {
        var cleanStep = line;
        cleanStep = cleanStep.replaceFirst(RegExp(r'^[*\-+]\s*(\[[ xX]\])?\s*'), '');
        final isCompleted = line.contains('[x]') || line.contains('[X]');
        if (cleanStep.isNotEmpty) {
          currentSubtasks.add(AtomicStep(
            id: 'step_${DateTime.now().microsecondsSinceEpoch}_${currentSubtasks.length}',
            title: cleanStep,
            isCompleted: isCompleted,
          ));
        }
        continue;
      }

      // Ignore top-level markdown headers like # Pin Tasks
      if (line.startsWith('#') && !line.startsWith('# ')) {
        if (line.startsWith('## ') || line.startsWith('### ')) {
          continue;
        }
      } else if (line.startsWith('# ')) {
        continue;
      }

      // New top-level task line
      commitCurrentTask();

      var cleanTitle = line;
      cleanTitle = cleanTitle.replaceFirst(RegExp(r'^[*\-+]\s*(\[[ xX]\])?\s*'), '');
      cleanTitle = cleanTitle.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');
      cleanTitle = cleanTitle.replaceFirst(RegExp(r'^📌\s*'), '');

      final isDone = line.contains('[x]') || line.contains('[X]');

      // Extract duration if present, e.g. (30m) or (45 min)
      var estimateMinutes = 15;
      final durationMatch = durationRegex.firstMatch(cleanTitle);
      if (durationMatch != null) {
        estimateMinutes = int.tryParse(durationMatch.group(1) ?? '') ?? 15;
        cleanTitle = cleanTitle.replaceFirst(durationMatch.group(0)!, '').trim();
      }

      // Extract tags
      final tags = <String>[];
      for (final match in tagRegex.allMatches(cleanTitle)) {
        final tag = match.group(0);
        if (tag != null && !tags.contains(tag)) {
          tags.add(tag);
        }
      }
      cleanTitle = cleanTitle.replaceAll(tagRegex, '').trim();

      if (cleanTitle.isEmpty) continue;

      final now = DateTime.now();
      currentTask = PinTask(
        id: 'task_${now.microsecondsSinceEpoch}_${tasks.length}',
        title: cleanTitle,
        status: isDone ? TaskStatus.done : defaultStatus,
        estimatedMinutes: estimateMinutes,
        tags: tags.isNotEmpty ? tags : ['#imported'],
        createdAt: now,
        updatedAt: now,
        completedAt: isDone ? now : null,
      );
    }

    commitCurrentTask();
    return tasks;
  }
}
