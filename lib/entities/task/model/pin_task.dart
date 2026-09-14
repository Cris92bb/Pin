import 'atomic_step.dart';

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
      case 'in_progress':
        return TaskStatus.today;
      case 'completed':
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
        return 'completed';
      case TaskStatus.backlog:
        return 'backlog';
    }
  }
}

/// The core domain entity representing a Task (Pin) in Pin, aligned with Firebase Blueprint.
class PinTask {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String category; // 'routine' | 'deep_work' | 'admin'
  final String energyTag; // 'low-friction' | 'medium-flow' | 'deep-focus' | 'creative' | 'admin'
  final String intensity; // 'recovery' | 'standard' | 'focus'
  final String source; // 'manual' | 'voice' | 'vision' | 'breakdown'
  final String? scheduledFor;
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
    this.category = 'routine',
    this.energyTag = 'low-friction',
    this.intensity = 'standard',
    this.source = 'manual',
    this.scheduledFor,
    this.estimatedMinutes = 15,
    this.trackedSeconds = 0,
    this.isPinned = false,
    this.tags = const [],
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  String get energy {
    final lower = energyTag.toLowerCase();
    if (lower.contains('deep') || lower.contains('high') || lower.contains('focus')) {
      return 'high';
    } else if (lower.contains('medium') || lower.contains('flow')) {
      return 'medium';
    }
    return 'low';
  }

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
    String? category,
    String? energyTag,
    String? intensity,
    String? source,
    String? scheduledFor,
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
      category: category ?? this.category,
      energyTag: energyTag ?? this.energyTag,
      intensity: intensity ?? this.intensity,
      source: source ?? this.source,
      scheduledFor: scheduledFor ?? this.scheduledFor,
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
      'category': category,
      'energy': energy,
      'intensity': intensity,
      'status': status == TaskStatus.done ? 'completed' : status.toStorageString(),
      'source': source,
      'pinned': isPinned,
      'isPinned': isPinned,
      'energyTag': energyTag,
      'estimatedMinutes': estimatedMinutes,
      'trackedSeconds': trackedSeconds,
      'tags': tags,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'scheduledFor': scheduledFor,
    };
  }

  factory PinTask.fromJson(Map<String, dynamic> json) {
    final parsedStatus = TaskStatus.fromString(json['status'] as String?);

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    // Determine category
    String cat = json['category'] as String? ?? '';
    if (cat.isEmpty) {
      final tagStr = (json['energyTag'] as String? ?? '').toLowerCase();
      if (tagStr.contains('admin')) {
        cat = 'admin';
      } else if (tagStr.contains('deep') || tagStr.contains('focus')) {
        cat = 'deep_work';
      } else {
        cat = 'routine';
      }
    }

    // Determine intensity
    String inten = json['intensity'] as String? ?? '';
    if (inten.isEmpty) {
      final energyStr = (json['energy'] as String? ?? json['energyTag'] as String? ?? '').toLowerCase();
      if (energyStr.contains('deep') || energyStr.contains('high') || energyStr.contains('focus')) {
        inten = 'focus';
      } else if (energyStr.contains('low') || energyStr.contains('recovery')) {
        inten = 'recovery';
      } else {
        inten = 'standard';
      }
    }

    return PinTask(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled Pin',
      description: json['description'] as String? ?? '',
      status: parsedStatus,
      category: cat,
      energyTag: json['energyTag'] as String? ?? (json['energy'] == 'high' ? 'deep-focus' : 'low-friction'),
      intensity: inten,
      source: json['source'] as String? ?? 'manual',
      scheduledFor: json['scheduledFor'] as String?,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 15,
      trackedSeconds: (json['trackedSeconds'] as num?)?.toInt() ?? 0,
      isPinned: json['pinned'] as bool? ?? json['isPinned'] as bool? ?? (parsedStatus == TaskStatus.today),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => AtomicStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      completedAt: parseNullableDate(json['completedAt']),
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
