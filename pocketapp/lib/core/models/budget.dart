import 'transaction.dart';

enum BudgetStatus { normal, nearLimit, exceeded }

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

  Budget copyWith({
    String? id,
    TransactionCategory? category,
    int? limitPaise,
    int? spentPaise,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limitPaise: limitPaise ?? this.limitPaise,
      spentPaise: spentPaise ?? this.spentPaise,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'limitPaise': limitPaise,
      'spentPaise': spentPaise,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: TransactionCategoryExtension.fromString(json['category'] as String? ?? 'other'),
      limitPaise: (json['limitPaise'] as num?)?.toInt() ?? 0,
      spentPaise: (json['spentPaise'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
    );
  }
}

// Sample data for optional testing
final List<Budget> sampleBudgets = [
  Budget(
    id: 'b1',
    category: TransactionCategory.food,
    limitPaise: 1500000,
    spentPaise: 0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  ),
  Budget(
    id: 'b2',
    category: TransactionCategory.transport,
    limitPaise: 500000,
    spentPaise: 0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  ),
  Budget(
    id: 'b3',
    category: TransactionCategory.shopping,
    limitPaise: 800000,
    spentPaise: 0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  ),
  Budget(
    id: 'b4',
    category: TransactionCategory.entertainment,
    limitPaise: 300000,
    spentPaise: 0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  ),
  Budget(
    id: 'b5',
    category: TransactionCategory.utilities,
    limitPaise: 400000,
    spentPaise: 0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  ),
];
