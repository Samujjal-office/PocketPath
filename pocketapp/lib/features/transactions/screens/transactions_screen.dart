import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/transaction.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/month_selector.dart';
import '../widgets/transaction_details_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _storageService = StorageService();

  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDirection; // 'Income', 'Expense', null
  TransactionCategory? _selectedCategory;
  String _selectedMonth = 'All Months';

  List<Transaction> _transactions = [];

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

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txs = await _storageService.getTransactions();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _transactions = txs;
    });
  }

  List<Transaction> get _filtered {
    return _transactions.where((tx) {
      final qMatch = _searchQuery.isEmpty ||
          tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final directionMatch = _selectedDirection == null ||
          ((_selectedDirection == 'Income') ==
              (tx.direction == TransactionDirection.income));

      final categoryMatch =
          _selectedCategory == null || tx.category == _selectedCategory;

      final monthMatch = _selectedMonth == 'All Months' ||
          _formatMonthYear(tx.dateTime) == _selectedMonth;

      return qMatch && directionMatch && categoryMatch && monthMatch;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month]} ${dt.year}';
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

  void _showDownloadStatementDialog() {
    final txsToExport = _filtered;
    if (txsToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export. Add some transactions first.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    final totalIncome = txsToExport
        .where((t) => t.direction == TransactionDirection.income)
        .fold<int>(0, (sum, t) => sum + t.amountPaise);
    final totalExpense = txsToExport
        .where((t) => t.direction == TransactionDirection.expense)
        .fold<int>(0, (sum, t) => sum + t.amountPaise);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.file_download_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download Statement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Export transactions to phone storage',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _StatementSummaryRow(
                      label: 'Filter Scope',
                      value: _selectedMonth,
                    ),
                    const Divider(height: 16),
                    _StatementSummaryRow(
                      label: 'Total Entries',
                      value: '${txsToExport.length} transactions',
                    ),
                    const Divider(height: 16),
                    _StatementSummaryRow(
                      label: 'Total Income',
                      value: CurrencyFormatter.formatPaise(totalIncome),
                      valueColor: AppColors.incomeGreen,
                    ),
                    const Divider(height: 16),
                    _StatementSummaryRow(
                      label: 'Total Expenses',
                      value: CurrencyFormatter.formatPaise(totalExpense),
                      valueColor: AppColors.expenseRed,
                    ),
                    const Divider(height: 16),
                    const _StatementSummaryRow(
                      label: 'File Format',
                      value: 'CSV Spreadsheet (.csv)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _handleShareStatement(txsToExport);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share File'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _handleDownloadStatement(txsToExport);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Save to Storage'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownloadStatement(List<Transaction> txs) async {
    try {
      final file = await _storageService.downloadStatement(transactions: txs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statement saved to:\n${file.path}'),
          backgroundColor: AppColors.incomeGreen,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'SHARE',
            textColor: Colors.white,
            onPressed: () => _handleShareStatement(txs),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download statement: $e'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  Future<void> _handleShareStatement(List<Transaction> txs) async {
    try {
      await _storageService.downloadAndShareStatement(transactions: txs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share statement: $e'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: _showDownloadStatementDialog,
            icon: const Icon(Icons.download_for_offline_rounded),
            tooltip: 'Download Statement',
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index) =>
                        const SkeletonTransactionItem(),
                  )
                : _filtered.isEmpty
                    ? EmptyState(
                        emoji: '🧾',
                        title: _transactions.isEmpty
                            ? 'No transactions yet'
                            : 'No matching transactions',
                        subtitle: _transactions.isEmpty
                            ? 'Add your first income or expense to start tracking!'
                            : 'Try adjusting your search or filter criteria.',
                        action: _transactions.isEmpty
                            ? ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed('/add-expense')
                                      .then((_) => _loadTransactions());
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Transaction'),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadTransactions,
                        child: _buildList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDownloadStatementDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.file_download_rounded, color: Colors.white),
        label: const Text(
          'Download Statement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
            isSelected: _selectedMonth != 'All Months',
            onTap: () => _showMonthPicker(),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedDirection ?? 'All Types',
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
          if (_selectedDirection != null ||
              _selectedCategory != null ||
              _selectedMonth != 'All Months') ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Clear',
              icon: Icons.close_rounded,
              isSelected: false,
              onTap: () => setState(() {
                _selectedDirection = null;
                _selectedCategory = null;
                _selectedMonth = 'All Months';
              }),
            ),
          ]
        ],
      ),
    );
  }

  void _showMonthPicker() {
    final availableMonths = ['All Months', ...kMonthOptions];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter by Month',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ),
            Expanded(
              child: ListView(
                children: availableMonths
                    .map((m) => ListTile(
                          title: Text(m),
                          trailing: m == _selectedMonth
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedMonth = m);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _cycleDirection() {
    setState(() {
      if (_selectedDirection == null) {
        _selectedDirection = 'Expense';
      } else if (_selectedDirection == 'Expense') {
        _selectedDirection = 'Income';
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
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: keys.length,
      itemBuilder: (context, i) {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
      builder: (_) => TransactionDetailsSheet(
        transaction: tx,
        onDelete: () async {
          await _storageService.deleteTransaction(tx.id);
          await _loadTransactions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction deleted from storage'),
                backgroundColor: AppColors.neutralGrey,
              ),
            );
          }
        },
      ),
    );
  }
}

class _StatementSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatementSummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            color: AppColors.incomeGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Stored',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.incomeGreen,
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
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () => onSelect(null),
          ),
          ...categories.map((c) => ListTile(
                leading:
                    Text(c.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(c.displayName),
                trailing: c == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => onSelect(c),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
