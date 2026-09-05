import '../../atomic_step/model/atomic_step.dart';

enum TaskStatus {
  backlog,
  today,
  done;

  String get label {
    switch (this) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.today:
        return 'To do';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromString(String? val) {
    switch (val) {
      case 'today':
        return TaskStatus.today;
      case 'done':
        return TaskStatus.done;
      case 'backlog':
      default:
        return TaskStatus.backlog;
    }
  }

  String toStorageString() {
    switch (this) {
      case TaskStatus.today:
        return 'today';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.backlog:
        return 'backlog';
    }
  }
}

/// The core domain entity representing a Task (Pin) in Pin.
class PinTask {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String energyTag;
  final int estimatedMinutes;
  final int trackedSeconds;
  final bool isPinned;
  final List<String> tags;
  final List<AtomicStep> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const PinTask({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.backlog,
    this.energyTag = 'low-friction',
    this.estimatedMinutes = 15,
    this.trackedSeconds = 0,
    this.isPinned = false,
    this.tags = const [],
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  int get completedSubtasksCount =>
      subtasks.where((s) => s.isCompleted).length;

  int get totalSubtasksCount => subtasks.length;

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0.0;
    return completedSubtasksCount / totalSubtasksCount;
  }

  bool get hasSubtasks => subtasks.isNotEmpty;

  String get energyDisplayLabel {
    final lower = energyTag.toLowerCase();
    if (lower.contains('deep') || lower.contains('focus')) {
      return 'DEEP FOCUS';
    } else if (lower.contains('medium') || lower.contains('flow')) {
      return 'MEDIUM FLOW';
    } else if (lower.contains('creative')) {
      return 'CREATIVE';
    } else if (lower.contains('admin')) {
      return 'ADMIN';
    }
    return 'LOW EFFORT';
  }

  String get energyEmoji {
    final lower = energyTag.toLowerCase();
    if (lower.contains('deep') || lower.contains('focus')) {
      return '⚡';
    } else if (lower.contains('medium') || lower.contains('flow')) {
      return '📇';
    } else if (lower.contains('creative')) {
      return '🎨';
    } else if (lower.contains('admin')) {
      return '📋';
    }
    return '☕';
  }

  PinTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    String? energyTag,
    int? estimatedMinutes,
    int? trackedSeconds,
    bool? isPinned,
    List<String>? tags,
    List<AtomicStep>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return PinTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      energyTag: energyTag ?? this.energyTag,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      trackedSeconds: trackedSeconds ?? this.trackedSeconds,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toStorageString(),
      'energyTag': energyTag,
      'estimatedMinutes': estimatedMinutes,
      'trackedSeconds': trackedSeconds,
      'isPinned': isPinned,
      'tags': tags,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PinTask.fromJson(Map<String, dynamic> json) {
    final parsedStatus = TaskStatus.fromString(json['status'] as String?);
    return PinTask(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled Pin',
      description: json['description'] as String? ?? '',
      status: parsedStatus,
      energyTag: json['energyTag'] as String? ?? 'low-friction',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 15,
      trackedSeconds: (json['trackedSeconds'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? (parsedStatus == TaskStatus.today),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => AtomicStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          status == other.status &&
          energyTag == other.energyTag &&
          estimatedMinutes == other.estimatedMinutes &&
          trackedSeconds == other.trackedSeconds &&
          isPinned == other.isPinned &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        status,
        energyTag,
        estimatedMinutes,
        trackedSeconds,
        isPinned,
        createdAt,
      );
}
