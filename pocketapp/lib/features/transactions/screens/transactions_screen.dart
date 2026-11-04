import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/transaction.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/transaction_details_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDirection; // 'Income', 'Expense', null
  TransactionCategory? _selectedCategory;
  String _selectedMonth = 'October 2026';

  List<Transaction> _transactions = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
      _transactions = List.from(sampleTransactions);
    });
  }

  List<Transaction> get _filtered {
    return _transactions.where((tx) {
      final qMatch = _searchQuery.isEmpty ||
          tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final directionMatch = _selectedDirection == null ||
          ((_selectedDirection == 'Income') ==
              (tx.direction == TransactionDirection.income));
      final categoryMatch =
          _selectedCategory == null || tx.category == _selectedCategory;
      return qMatch && directionMatch && categoryMatch;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Map<String, List<Transaction>> get _grouped {
    final filtered = _filtered;
    final Map<String, List<Transaction>> groups = {};
    for (final tx in filtered) {
      final label = _dateGroupLabel(tx.dateTime);
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  String _dateGroupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(txDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 8,
                    itemBuilder: (_, __) => const SkeletonTransactionItem(),
                  )
                : _filtered.isEmpty
                    ? const EmptyState(
                        emoji: '🔍',
                        title: 'No transactions found',
                        subtitle:
                            'Try adjusting your search or filter criteria.',
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => _loadTransactions(),
                        child: _buildList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search merchant or note…',
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textMedium),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textMedium),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: _selectedMonth,
            icon: Icons.calendar_month_rounded,
            isSelected: true,
            onTap: () => _showMonthPicker(),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedDirection ?? 'All',
            icon: Icons.swap_vert_rounded,
            isSelected: _selectedDirection != null,
            onTap: () => _cycleDirection(),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedCategory?.displayName ?? 'Category',
            icon: Icons.category_rounded,
            isSelected: _selectedCategory != null,
            onTap: () => _showCategoryPicker(),
          ),
          if (_selectedDirection != null || _selectedCategory != null) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Clear',
              icon: Icons.close_rounded,
              isSelected: false,
              onTap: () => setState(() {
                _selectedDirection = null;
                _selectedCategory = null;
              }),
            ),
          ]
        ],
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _MonthPickerSheet(
        selected: _selectedMonth,
        onSelect: (m) {
          setState(() => _selectedMonth = m);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _cycleDirection() {
    setState(() {
      if (_selectedDirection == null) {
        _selectedDirection = 'Income';
      } else if (_selectedDirection == 'Income') {
        _selectedDirection = 'Expense';
      } else {
        _selectedDirection = null;
      }
    });
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _CategoryPickerSheet(
        selected: _selectedCategory,
        onSelect: (c) {
          setState(() => _selectedCategory = c);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildList() {
    final groups = _grouped;
    final keys = groups.keys.toList();

    return ListView.builder(
      itemCount: keys.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == keys.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }
        final key = keys[i];
        final txs = groups[key]!;
        return _buildGroup(key, txs);
      },
    );
  }

  Widget _buildGroup(String label, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final tx = entry.value;
              return Column(
                children: [
                  _TransactionListItem(
                    transaction: tx,
                    onTap: () => _showDetails(tx),
                  ),
                  if (index < transactions.length - 1)
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _showDetails(Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(transaction: tx),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : AppColors.neutralGreyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.primaryDark
                  : AppColors.textMedium,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionListItem(
      {required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.direction == TransactionDirection.income;
    final amountColor =
        isIncome ? AppColors.incomeGreen : AppColors.textDark;
    final amountPrefix = isIncome ? '+' : '-';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${transaction.dateTime.day} ${months[transaction.dateTime.month]}, '
        '${_pad(transaction.dateTime.hour)}:${_pad(transaction.dateTime.minute)}';

    Color statusColor;
    String statusLabel;
    switch (transaction.status) {
      case TransactionStatus.pending:
        statusColor = AppColors.warningOchre;
        statusLabel = 'Pending';
        break;
      case TransactionStatus.failed:
        statusColor = AppColors.expenseRed;
        statusLabel = 'Failed (Network)';
        break;
      case TransactionStatus.synced:
        statusColor = AppColors.incomeGreen;
        statusLabel = 'Synced';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppColors.incomeGreenLight
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    transaction.category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$amountPrefix${CurrencyFormatter.formatPaise(transaction.amountPaise)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _MonthPickerSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _MonthPickerSheet(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const months = [
      'January 2026', 'February 2026', 'March 2026', 'April 2026',
      'May 2026', 'June 2026', 'July 2026', 'August 2026',
      'September 2026', 'October 2026', 'November 2026', 'December 2026',
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Month',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
          ),
          ...months.map((m) => ListTile(
                title: Text(m),
                trailing: m == selected
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () => onSelect(m),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory?> onSelect;

  const _CategoryPickerSheet(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategory.values;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filter by Category',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
          ),
          ListTile(
            title: const Text('All Categories'),
            trailing: selected == null
                ? const Icon(Icons.check_rounded,
                    color: AppColors.primary)
                : null,
            onTap: () => onSelect(null),
          ),
          ...categories.map((c) => ListTile(
                leading:
                    Text(c.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(c.displayName),
                trailing: c == selected
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () => onSelect(c),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
