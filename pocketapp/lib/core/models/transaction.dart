enum TransactionDirection { income, expense }

enum TransactionStatus { pending, failed, synced }

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  health,
  utilities,
  education,
  salary,
  investment,
  other,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.food: return 'Food & Dining';
      case TransactionCategory.transport: return 'Transport';
      case TransactionCategory.shopping: return 'Shopping';
      case TransactionCategory.entertainment: return 'Entertainment';
      case TransactionCategory.health: return 'Health';
      case TransactionCategory.utilities: return 'Utilities';
      case TransactionCategory.education: return 'Education';
      case TransactionCategory.salary: return 'Salary';
      case TransactionCategory.investment: return 'Investment';
      case TransactionCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case TransactionCategory.food: return '🍽️';
      case TransactionCategory.transport: return '🚗';
      case TransactionCategory.shopping: return '🛍️';
      case TransactionCategory.entertainment: return '🎬';
      case TransactionCategory.health: return '💊';
      case TransactionCategory.utilities: return '💡';
      case TransactionCategory.education: return '📚';
      case TransactionCategory.salary: return '💼';
      case TransactionCategory.investment: return '📈';
      case TransactionCategory.other: return '📦';
    }
  }

  static TransactionCategory fromString(String name) {
    return TransactionCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => TransactionCategory.other,
    );
  }
}

class Transaction {
  final String id;
  final String merchant;
  final TransactionCategory category;
  final TransactionDirection direction;
  final int amountPaise;
  final DateTime dateTime;
  final TransactionStatus status;
  final String? note;

  const Transaction({
    required this.id,
    required this.merchant,
    required this.category,
    required this.direction,
    required this.amountPaise,
    required this.dateTime,
    required this.status,
    this.note,
  });

  Transaction copyWith({
    String? id,
    String? merchant,
    TransactionCategory? category,
    TransactionDirection? direction,
    int? amountPaise,
    DateTime? dateTime,
    TransactionStatus? status,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      direction: direction ?? this.direction,
      amountPaise: amountPaise ?? this.amountPaise,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant': merchant,
      'category': category.name,
      'direction': direction.name,
      'amountPaise': amountPaise,
      'dateTime': dateTime.toIso8601String(),
      'status': status.name,
      'note': note,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      merchant: json['merchant'] as String? ?? 'Unknown',
      category: TransactionCategoryExtension.fromString(json['category'] as String? ?? 'other'),
      direction: (json['direction'] as String? ?? 'expense') == 'income'
          ? TransactionDirection.income
          : TransactionDirection.expense,
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.synced,
      ),
      note: json['note'] as String?,
    );
  }
}

// Sample data kept only for optional seeding in development
final List<Transaction> sampleTransactions = [
  Transaction(
    id: '1',
    merchant: 'Swiggy',
    category: TransactionCategory.food,
    direction: TransactionDirection.expense,
    amountPaise: 34900,
    dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    status: TransactionStatus.synced,
    note: 'Dinner with team',
  ),
  Transaction(
    id: '2',
    merchant: 'Ola Cabs',
    category: TransactionCategory.transport,
    direction: TransactionDirection.expense,
    amountPaise: 22000,
    dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    status: TransactionStatus.synced,
  ),
  Transaction(
    id: '3',
    merchant: 'Salary Credit',
    category: TransactionCategory.salary,
    direction: TransactionDirection.income,
    amountPaise: 8500000,
    dateTime: DateTime.now().subtract(const Duration(days: 5)),
    status: TransactionStatus.synced,
    note: 'Monthly salary',
  ),
  Transaction(
    id: '4',
    merchant: 'Amazon',
    category: TransactionCategory.shopping,
    direction: TransactionDirection.expense,
    amountPaise: 189900,
    dateTime: DateTime.now().subtract(const Duration(days: 6)),
    status: TransactionStatus.pending,
  ),
  Transaction(
    id: '5',
    merchant: 'Netflix',
    category: TransactionCategory.entertainment,
    direction: TransactionDirection.expense,
    amountPaise: 64900,
    dateTime: DateTime.now().subtract(const Duration(days: 8)),
    status: TransactionStatus.failed,
    note: 'Monthly subscription',
  ),
  Transaction(
    id: '6',
    merchant: 'Apollo Pharmacy',
    category: TransactionCategory.health,
    direction: TransactionDirection.expense,
    amountPaise: 87500,
    dateTime: DateTime.now().subtract(const Duration(days: 10)),
    status: TransactionStatus.synced,
  ),
  Transaction(
    id: '7',
    merchant: 'Electricity Board',
    category: TransactionCategory.utilities,
    direction: TransactionDirection.expense,
    amountPaise: 234000,
    dateTime: DateTime.now().subtract(const Duration(days: 12)),
    status: TransactionStatus.synced,
    note: 'Electricity bill',
  ),
  Transaction(
    id: '8',
    merchant: 'Zomato',
    category: TransactionCategory.food,
    direction: TransactionDirection.expense,
    amountPaise: 45600,
    dateTime: DateTime.now().subtract(const Duration(days: 15)),
    status: TransactionStatus.synced,
  ),
];
