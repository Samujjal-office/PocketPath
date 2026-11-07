class SavingsGoal {
  final String id;
  final String title;
  final int targetPaise;
  final int savedPaise;
  final DateTime targetDate;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetPaise,
    required this.savedPaise,
    required this.targetDate,
  });

  double get progressRatio =>
      targetPaise > 0 ? (savedPaise / targetPaise).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => savedPaise >= targetPaise;

  SavingsGoal copyWith({
    String? id,
    String? title,
    int? targetPaise,
    int? savedPaise,
    DateTime? targetDate,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetPaise: targetPaise ?? this.targetPaise,
      savedPaise: savedPaise ?? this.savedPaise,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetPaise': targetPaise,
      'savedPaise': savedPaise,
      'targetDate': targetDate.toIso8601String(),
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Goal',
      targetPaise: (json['targetPaise'] as num?)?.toInt() ?? 0,
      savedPaise: (json['savedPaise'] as num?)?.toInt() ?? 0,
      targetDate: DateTime.tryParse(json['targetDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
    );
  }
}

final List<SavingsGoal> sampleGoals = [
  SavingsGoal(
    id: 'g1',
    title: 'Emergency Fund',
    targetPaise: 30000000,
    savedPaise: 18500000,
    targetDate: DateTime.now().add(const Duration(days: 180)),
  ),
  SavingsGoal(
    id: 'g2',
    title: 'Vacation',
    targetPaise: 8000000,
    savedPaise: 5600000,
    targetDate: DateTime.now().add(const Duration(days: 120)),
  ),
];
