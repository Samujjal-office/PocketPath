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
}

final List<SavingsGoal> sampleGoals = [
  SavingsGoal(
    id: 'g1',
    title: 'Emergency Fund',
    targetPaise: 30000000,
    savedPaise: 18500000,
    targetDate: DateTime(2027, 3, 31),
  ),
  SavingsGoal(
    id: 'g2',
    title: 'Vacation — Bali',
    targetPaise: 8000000,
    savedPaise: 5600000,
    targetDate: DateTime(2027, 6, 1),
  ),
  SavingsGoal(
    id: 'g3',
    title: 'New Laptop',
    targetPaise: 12000000,
    savedPaise: 12000000,
    targetDate: DateTime(2026, 12, 31),
  ),
];
