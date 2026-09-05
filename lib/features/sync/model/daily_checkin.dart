/// Morning grooming check-in data representing energy readiness and cognitive capacity.
class DailyCheckin {
  final int energyScore; // 1 to 100
  final String cognitiveCapacity; // 'low_recovery' | 'steady' | 'peak_focus'
  final String routineRecommendation;
  final String notes;
  final DateTime checkedInAt;

  const DailyCheckin({
    this.energyScore = 75,
    this.cognitiveCapacity = 'steady',
    this.routineRecommendation = 'Standard Focus Sprint',
    this.notes = '',
    required this.checkedInAt,
  });

  static String calculateCapacity(int score) {
    if (score < 40) return 'low_recovery';
    if (score < 75) return 'steady';
    return 'peak_focus';
  }

  static String defaultRoutine(int score) {
    if (score < 40) {
      return 'Gentle mobility, low-friction admin, frequent hydration pauses';
    } else if (score < 75) {
      return 'Steady work blocks, moderate deep focus with 15-minute intervals';
    } else {
      return 'Peak energy deep work, challenging tasks, high cognitive sprint';
    }
  }

  Map<String, dynamic> toJson() => {
        'energyScore': energyScore,
        'cognitiveCapacity': cognitiveCapacity,
        'routineRecommendation': routineRecommendation,
        'notes': notes,
        'checkedInAt': checkedInAt.toIso8601String(),
      };

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    final score = (json['energyScore'] as num?)?.toInt() ?? 75;
    return DailyCheckin(
      energyScore: score,
      cognitiveCapacity: json['cognitiveCapacity'] as String? ?? calculateCapacity(score),
      routineRecommendation: json['routineRecommendation'] as String? ?? defaultRoutine(score),
      notes: json['notes'] as String? ?? '',
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.tryParse(json['checkedInAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
