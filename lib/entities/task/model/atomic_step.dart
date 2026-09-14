/// An atomic subtask constrained to a bite-sized scope (<= 15 minutes).
class AtomicStep {
  final String id;
  final String title;
  final bool isCompleted;
  final int estimatedMinutes; // Constrained to <= 15 minutes

  const AtomicStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.estimatedMinutes = 15,
  }) : assert(estimatedMinutes <= 15, 'Atomic steps must be <= 15 minutes');

  AtomicStep copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? estimatedMinutes,
  }) {
    return AtomicStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  factory AtomicStep.fromJson(Map<String, dynamic> json) {
    return AtomicStep(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 15,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtomicStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          estimatedMinutes == other.estimatedMinutes;

  @override
  int get hashCode => Object.hash(id, title, isCompleted, estimatedMinutes);
}
