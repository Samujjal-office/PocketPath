import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/budget.dart';
import '../../../core/models/transaction.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/month_selector.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late String _selectedMonth;
  bool _isLoading = true;
  final bool _isOffline = false;
  List<Budget> _budgets = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = getCurrentMonthString();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final selectedDt = parseMonthYear(_selectedMonth);
    await StorageService().recalculateBudgets();
    final list = await StorageService().getBudgets(
      month: selectedDt.month,
      year: selectedDt.year,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _budgets = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Category Budgets'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: _showAddBudgetSheet,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Budget',
            color: AppColors.primary,
          ),
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
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonCard(height: 120),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: _budgets.isEmpty
                  ? EmptyState(
                      emoji: '📊',
                      title: 'No budgets for $_selectedMonth',
                      subtitle:
                          'Set spending limits for your categories to track expenses on your phone.',
                      action: ElevatedButton.icon(
                        onPressed: _showAddBudgetSheet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Budget'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _budgets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        return _BudgetCard(
                          budget: _budgets[i],
                          isOffline: _isOffline,
                          onEditLimit: () =>
                              _showEditLimitSheet(_budgets[i]),
                        );
                      },
                    ),
            ),
    );
  }

  void _showAddBudgetSheet() {
    final existingCategories = _budgets.map((b) => b.category).toSet();
    final availableCategories = TransactionCategory.values
        .where((c) =>
            c != TransactionCategory.salary &&
            c != TransactionCategory.investment &&
            !existingCategories.contains(c))
        .toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All categories already have a budget for this month!'),
          backgroundColor: AppColors.neutralGrey,
        ),
      );
      return;
    }

    TransactionCategory selectedCat = availableCategories.first;
    final limitController = TextEditingController(text: '5000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Category Budget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionCategory>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: availableCategories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.emoji}  ${c.displayName}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedCat = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit (₹)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final rupees = int.tryParse(limitController.text) ?? 5000;
                      final selectedDt = parseMonthYear(_selectedMonth);
                      final newBudget = Budget(
                        id: 'b_${selectedCat.name}_${selectedDt.month}_${selectedDt.year}',
                        category: selectedCat,
                        limitPaise: rupees * 100,
                        spentPaise: 0,
                        month: selectedDt.month,
                        year: selectedDt.year,
                      );
                      await StorageService().saveBudgets([newBudget]);
                      await StorageService().recalculateBudgets();
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadData();
                    },
                    child: const Text('Add Budget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditLimitSheet(Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditLimitSheet(
        budget: budget,
        isOffline: _isOffline,
        onSave: (newLimit) async {
          await StorageService().updateBudgetLimit(budget.id, newLimit);
          if (!sheetContext.mounted) return;
          Navigator.pop(sheetContext);
          _loadData();
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final bool isOffline;
  final VoidCallback onEditLimit;

  const _BudgetCard({
    required this.budget,
    required this.isOffline,
    required this.onEditLimit,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = budget.utilizationRatio;
    final displayRatio = ratio.clamp(0.0, 1.0);
    final percentage = (ratio * 100).toStringAsFixed(0);

    Color statusColor;
    String statusLabel;
    Color statusBgColor;
    switch (budget.status) {
      case BudgetStatus.exceeded:
        statusColor = AppColors.crimson;
        statusBgColor = AppColors.crimsonLight;
        statusLabel = 'Exceeded';
        break;
      case BudgetStatus.nearLimit:
        statusColor = AppColors.warningOchre;
        statusBgColor = AppColors.warningOchreLight;
        statusLabel = 'Near Limit';
        break;
      case BudgetStatus.normal:
        statusColor = AppColors.neutralGrey;
        statusBgColor = AppColors.neutralGreyLight;
        statusLabel = 'On Track';
        break;
    }

    return Container(
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
              Row(
                children: [
                  Text(budget.category.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    budget.category.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatPaise(
                              budget.spentPaise),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: budget.status ==
                                    BudgetStatus.exceeded
                                ? AppColors.crimson
                                : AppColors.textDark,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${CurrencyFormatter.formatPaise(budget.limitPaise)} limit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: displayRatio,
              backgroundColor: AppColors.neutralGreyLight,
              valueColor:
                  AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEditLimit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: const Size(48, 36),
              ),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text(
                'Edit Limit',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditLimitSheet extends StatefulWidget {
  final Budget budget;
  final bool isOffline;
  final ValueChanged<int> onSave;

  const _EditLimitSheet({
    required this.budget,
    required this.isOffline,
    required this.onSave,
  });

  @override
  State<_EditLimitSheet> createState() => _EditLimitSheetState();
}

class _EditLimitSheetState extends State<_EditLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final rupeesStr =
        (widget.budget.limitPaise / 100).toStringAsFixed(0);
    _controller = TextEditingController(text: rupeesStr);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardFill,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.budget.category.emoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                const Text(
                  'Edit Budget Limit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.budget.category.displayName,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'New Limit (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Limit is required';
                  final val = int.tryParse(v.replaceAll(',', ''));
                  if (val == null || val <= 0) {
                    return 'Enter a positive non-zero amount';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final rupees = int.parse(
                            _controller.text.replaceAll(',', ''));
                        widget.onSave(rupees * 100);
                      }
                    },
                    child: const Text('Save Limit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
