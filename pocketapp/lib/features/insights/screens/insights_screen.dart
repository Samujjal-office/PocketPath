import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/transaction.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/month_selector.dart';
import '../../../core/widgets/empty_state.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late String _selectedMonth;
  bool _isLoading = true;

  int _highestSpendPaise = 0;
  String _highestSpendRange = 'No data';
  List<_CategorySpend> _categorySpends = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = getCurrentMonthString();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final storage = StorageService();
    final allTxs = await storage.getTransactions();
    final selectedDt = parseMonthYear(_selectedMonth);

    // Filter expenses in this month & year
    final monthExpenses = allTxs.where((t) =>
        t.direction == TransactionDirection.expense &&
        t.dateTime.month == selectedDt.month &&
        t.dateTime.year == selectedDt.year).toList();

    // Group expenses by category
    final Map<TransactionCategory, int> catTotals = {};
    for (final tx in monthExpenses) {
      catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amountPaise;
    }

    final budgets = await storage.getBudgets(
      month: selectedDt.month,
      year: selectedDt.year,
    );

    final List<_CategorySpend> spends = [];
    for (final entry in catTotals.entries) {
      final b = budgets.where((b) => b.category == entry.key).firstOrNull;
      spends.add(_CategorySpend(
        entry.key,
        entry.value,
        b?.limitPaise ?? 0,
      ));
    }
    spends.sort((a, b) => b.spentPaise.compareTo(a.spentPaise));

    // Calculate highest 7-day spend in this month
    int max7Day = 0;
    String max7DayRange = 'Month to date';

    if (monthExpenses.isNotEmpty) {
      // Aggregate by day of month (1..31)
      final Map<int, int> daySpend = {};
      for (final tx in monthExpenses) {
        final d = tx.dateTime.day;
        daySpend[d] = (daySpend[d] ?? 0) + tx.amountPaise;
      }

      int bestSum = 0;
      int bestStartDay = 1;
      for (int start = 1; start <= 24; start++) {
        int windowSum = 0;
        for (int i = 0; i < 7; i++) {
          windowSum += daySpend[start + i] ?? 0;
        }
        if (windowSum > bestSum) {
          bestSum = windowSum;
          bestStartDay = start;
        }
      }
      max7Day = bestSum;
      const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final mName = monthNames[selectedDt.month];
      max7DayRange = '$bestStartDay - ${bestStartDay + 6} $mName';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _highestSpendPaise = max7Day;
      _highestSpendRange = max7DayRange;
      _categorySpends = spends;
    });
  }

  int get _totalSpendPaise =>
      _categorySpends.fold(0, (sum, c) => sum + c.spentPaise);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spending Insights'),
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: MonthSelectorDropdown(
              selectedMonth: _selectedMonth,
              months: kMonthOptions,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedMonth = v);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SkeletonCard(height: 130),
                const SizedBox(height: 16),
                ...List.generate(
                    5,
                    (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SkeletonCard(height: 72),
                        )),
              ],
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: _categorySpends.isEmpty
                  ? EmptyState(
                      emoji: '📈',
                      title: 'No expenses for $_selectedMonth',
                      subtitle:
                          'Record expenses from the Add screen to see insightful breakdowns here.',
                      action: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/add-expense')
                            .then((_) => _loadData()),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Expense'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHighlightCard(),
                        const SizedBox(height: 20),
                        _buildCategoryBreakdown(),
                        const SizedBox(height: 16),
                        _buildFootnote(),
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Highest 7-Day Spend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatPaise(_highestSpendPaise),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 14, color: AppColors.primaryDark),
              const SizedBox(width: 4),
              Text(
                _highestSpendRange,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.primaryContainer, height: 1),
          const SizedBox(height: 12),
          Text(
            'Total this month: ${CurrencyFormatter.formatPaise(_totalSpendPaise)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final maxSpend =
        _categorySpends.isNotEmpty ? _categorySpends.first.spentPaise : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _categorySpends.asMap().entries.map((entry) {
              final index = entry.key;
              final spend = entry.value;
              final barRatio =
                  maxSpend > 0 ? spend.spentPaise / maxSpend : 0.0;
              final totalRatio = _totalSpendPaise > 0
                  ? spend.spentPaise / _totalSpendPaise
                  : 0.0;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(spend.category.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                spend.category.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(spend.spentPaise),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${(totalRatio * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: barRatio,
                            backgroundColor: AppColors.neutralGreyLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < _categorySpends.length - 1)
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
      ],
    );
  }

  Widget _buildFootnote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: AppColors.textMedium),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stored on phone storage. Calculated in real-time from your confirmed transactions.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySpend {
  final TransactionCategory category;
  final int spentPaise;
  final int limitPaise;

  _CategorySpend(this.category, this.spentPaise, this.limitPaise);
}
