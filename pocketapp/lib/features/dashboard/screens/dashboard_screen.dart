import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/budget.dart';
import '../../../core/models/savings_goal.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/month_selector.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _selectedMonth;
  bool _isLoading = true;
  final bool _isOffline = false;

  // Aggregated data
  int _totalIncomePaise = 0;
  int _totalExpensePaise = 0;
  Budget? _highestUtilizedBudget;
  SavingsGoal? _primaryGoal;
  List<Transaction> _recentTransactions = [];

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

    final monthTxs = allTxs.where((t) =>
        t.dateTime.month == selectedDt.month &&
        t.dateTime.year == selectedDt.year).toList();

    final income = monthTxs
        .where((t) => t.direction == TransactionDirection.income)
        .fold<int>(0, (sum, t) => sum + t.amountPaise);
    final expense = monthTxs
        .where((t) => t.direction == TransactionDirection.expense)
        .fold<int>(0, (sum, t) => sum + t.amountPaise);

    final budgets = await storage.getBudgets(
      month: selectedDt.month,
      year: selectedDt.year,
    );

    Budget? highestBudget;
    if (budgets.isNotEmpty) {
      highestBudget = budgets.reduce((a, b) =>
          a.utilizationRatio > b.utilizationRatio ? a : b);
    }

    final goals = await storage.getSavingsGoals();
    final primaryGoal = goals.isNotEmpty ? goals.first : null;

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _totalIncomePaise = income;
      _totalExpensePaise = expense;
      _highestUtilizedBudget = highestBudget;
      _primaryGoal = primaryGoal;
      _recentTransactions = allTxs.take(4).toList();
    });
  }

  int get _netCashFlow => _totalIncomePaise - _totalExpensePaise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_isOffline)
              const SliverToBoxAdapter(
                child: OfflineBanner(),
              ),
            if (_isLoading)
              SliverToBoxAdapter(child: _buildSkeletons())
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeroCard(),
                      if (_highestUtilizedBudget != null) ...[
                        const SizedBox(height: 16),
                        _buildBudgetWatchCard(),
                      ],
                      if (_primaryGoal != null) ...[
                        const SizedBox(height: 16),
                        _buildSavingsGoalCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildRecentTransactionsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      titleSpacing: 16,
      title: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome 👋',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'My PocketPath',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          MonthSelectorDropdown(
            selectedMonth: _selectedMonth,
            months: kMonthOptions,
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedMonth = v);
                _loadData();
              }
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/settings').then((_) => _loadData()),
          icon: const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.settings_rounded,
              size: 20,
              color: AppColors.primaryDark,
            ),
          ),
          tooltip: 'Settings & Profile',
        ),
      ],
    );
  }

  Widget _buildSkeletons() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const SkeletonCard(height: 140),
        const SkeletonCard(height: 100),
        const SkeletonCard(height: 100),
        ...List.generate(3, (_) => const SkeletonTransactionItem()),
      ],
    );
  }

  Widget _buildHeroCard() {
    final isPositive = _netCashFlow >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Month',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                _selectedMonth,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Net Cash Flow',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primaryDark.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatPaise(_netCashFlow.abs()),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isPositive ? AppColors.textDark : AppColors.crimson,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 20,
                  color: isPositive
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.primaryContainer, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFlowItem(
                  label: 'Income',
                  amount: _totalIncomePaise,
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.incomeGreen,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.primaryContainer,
              ),
              Expanded(
                child: _buildFlowItem(
                  label: 'Expenses',
                  amount: _totalExpensePaise,
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.expenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowItem({
    required String label,
    required int amount,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryDark.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatPaise(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetWatchCard() {
    if (_highestUtilizedBudget == null) return const SizedBox.shrink();
    final budget = _highestUtilizedBudget!;
    final ratio = budget.utilizationRatio.clamp(0.0, 1.2);
    Color statusColor;
    String statusLabel;
    switch (budget.status) {
      case BudgetStatus.exceeded:
        statusColor = AppColors.crimson;
        statusLabel = 'Exceeded';
        break;
      case BudgetStatus.nearLimit:
        statusColor = AppColors.warningOchre;
        statusLabel = 'Near Limit';
        break;
      case BudgetStatus.normal:
        statusColor = AppColors.neutralGrey;
        statusLabel = 'On Track';
        break;
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/budgets').then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.donut_small_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Budget Watch',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${budget.category.emoji}  ${budget.category.displayName}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: AppColors.neutralGreyLight,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CurrencyFormatter.formatPaise(budget.spentPaise)} spent',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
                Text(
                  'of ${CurrencyFormatter.formatPaise(budget.limitPaise)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsGoalCard() {
    if (_primaryGoal == null) return const SizedBox.shrink();
    final goal = _primaryGoal!;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/goals').then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.savings_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Savings Goal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(goal.progressRatio * 100).toStringAsFixed(0)}% saved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              goal.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressRatio,
                backgroundColor: AppColors.neutralGreyLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatPaise(goal.savedPaise),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
                Text(
                  'of ${CurrencyFormatter.formatPaise(goal.targetPaise)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/transactions').then((_) => _loadData()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                minimumSize: const Size(48, 36),
              ),
              child: const Text(
                'View All >',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentTransactions.isEmpty)
          EmptyState(
            emoji: '📭',
            title: 'No transactions yet',
            subtitle: 'Tap below to record your first income or expense.',
            action: ElevatedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushNamed('/add-expense')
                  .then((_) => _loadData()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Transaction'),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ..._recentTransactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;
                  return Column(
                    children: [
                      _TransactionRow(transaction: tx),
                      if (index < _recentTransactions.length - 1)
                        const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.direction == TransactionDirection.income;
    final amountColor =
        isIncome ? AppColors.incomeGreen : AppColors.textDark;
    final amountPrefix = isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Text(
                  transaction.category.displayName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
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
    );
  }
}
