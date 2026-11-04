import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/transaction.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/month_selector.dart';
import '../../../core/widgets/empty_state.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedMonth = 'October 2026';
  bool _isLoading = true;

  // Demo data
  int _highestSpendPaise = 0;
  String _highestSpendRange = '';
  List<_CategorySpend> _categorySpends = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _highestSpendPaise = 950000;
      _highestSpendRange = '15 - 21 Oct';
      _categorySpends = [
        _CategorySpend(TransactionCategory.food, 1100000, 1500000),
        _CategorySpend(TransactionCategory.shopping, 850000, 850000),
        _CategorySpend(TransactionCategory.utilities, 234000, 400000),
        _CategorySpend(TransactionCategory.transport, 320000, 500000),
        _CategorySpend(TransactionCategory.entertainment, 289000, 300000),
        _CategorySpend(TransactionCategory.health, 87500, 200000),
      ]..sort((a, b) => b.spentPaise.compareTo(a.spentPaise));
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
                    5, (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SkeletonCard(height: 72),
                        )),
              ],
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: _categorySpends.isEmpty
                  ? const EmptyState(
                      emoji: '📈',
                      title: 'No insights yet',
                      subtitle:
                          'Add some confirmed expenses to see spending insights.',
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
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
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
    final maxSpend = _categorySpends.isNotEmpty
        ? _categorySpends.first.spentPaise
        : 1;

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
                              CurrencyFormatter.formatPaise(
                                  spend.spentPaise),
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
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
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
              'Includes confirmed expenses only. Missing calendar days count as zero.',
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
