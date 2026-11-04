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
}

// Sample data for demo
final List<Transaction> sampleTransactions = [
  Transaction(
    id: '1',
    merchant: 'Swiggy',
    category: TransactionCategory.food,
    direction: TransactionDirection.expense,
    amountPaise: 34900,
    dateTime: DateTime(2026, 10, 28, 19, 30),
    status: TransactionStatus.synced,
    note: 'Dinner with team',
  ),
  Transaction(
    id: '2',
    merchant: 'Ola Cabs',
    category: TransactionCategory.transport,
    direction: TransactionDirection.expense,
    amountPaise: 22000,
    dateTime: DateTime(2026, 10, 27, 9, 15),
    status: TransactionStatus.synced,
  ),
  Transaction(
    id: '3',
    merchant: 'Salary Credit',
    category: TransactionCategory.salary,
    direction: TransactionDirection.income,
    amountPaise: 8500000,
    dateTime: DateTime(2026, 10, 25, 10, 0),
    status: TransactionStatus.synced,
    note: 'October 2026 salary',
  ),
  Transaction(
    id: '4',
    merchant: 'Amazon',
    category: TransactionCategory.shopping,
    direction: TransactionDirection.expense,
    amountPaise: 189900,
    dateTime: DateTime(2026, 10, 24, 14, 20),
    status: TransactionStatus.pending,
  ),
  Transaction(
    id: '5',
    merchant: 'Netflix',
    category: TransactionCategory.entertainment,
    direction: TransactionDirection.expense,
    amountPaise: 64900,
    dateTime: DateTime(2026, 10, 22, 11, 0),
    status: TransactionStatus.failed,
    note: 'Monthly subscription',
  ),
  Transaction(
    id: '6',
    merchant: 'Apollo Pharmacy',
    category: TransactionCategory.health,
    direction: TransactionDirection.expense,
    amountPaise: 87500,
    dateTime: DateTime(2026, 10, 20, 16, 45),
    status: TransactionStatus.synced,
  ),
  Transaction(
    id: '7',
    merchant: 'BESCOM',
    category: TransactionCategory.utilities,
    direction: TransactionDirection.expense,
    amountPaise: 234000,
    dateTime: DateTime(2026, 10, 18, 12, 0),
    status: TransactionStatus.synced,
    note: 'Electricity bill',
  ),
  Transaction(
    id: '8',
    merchant: 'Zomato',
    category: TransactionCategory.food,
    direction: TransactionDirection.expense,
    amountPaise: 45600,
    dateTime: DateTime(2026, 10, 15, 20, 0),
    status: TransactionStatus.synced,
  ),
];
