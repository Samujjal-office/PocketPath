import 'transaction.dart';

class Budget {
  final String id;
  final TransactionCategory category;
  final int limitPaise;
  final int spentPaise;
  final int month; // 1-12
  final int year;

  const Budget({
    required this.id,
    required this.category,
    required this.limitPaise,
    required this.spentPaise,
    required this.month,
    required this.year,
  });

  double get utilizationRatio =>
      limitPaise > 0 ? spentPaise / limitPaise : 0.0;

  BudgetStatus get status {
    final ratio = utilizationRatio;
    if (ratio > 1.0) return BudgetStatus.exceeded;
    if (ratio >= 0.8) return BudgetStatus.nearLimit;
    return BudgetStatus.normal;
  }
}

enum BudgetStatus { normal, nearLimit, exceeded }

final List<Budget> sampleBudgets = [
  Budget(
    id: 'b1',
    category: TransactionCategory.food,
    limitPaise: 1500000,
    spentPaise: 1100000,
    month: 10,
    year: 2026,
  ),
  Budget(
    id: 'b2',
    category: TransactionCategory.transport,
    limitPaise: 500000,
    spentPaise: 320000,
    month: 10,
    year: 2026,
  ),
  Budget(
    id: 'b3',
    category: TransactionCategory.shopping,
    limitPaise: 800000,
    spentPaise: 850000,
    month: 10,
    year: 2026,
  ),
  Budget(
    id: 'b4',
    category: TransactionCategory.entertainment,
    limitPaise: 300000,
    spentPaise: 289000,
    month: 10,
    year: 2026,
  ),
  Budget(
    id: 'b5',
    category: TransactionCategory.utilities,
    limitPaise: 400000,
    spentPaise: 234000,
    month: 10,
    year: 2026,
  ),
];
