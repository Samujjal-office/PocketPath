import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/savings_goal.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _isLoading = true;
  List<SavingsGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await StorageService().getSavingsGoals();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _goals = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _showCreateGoalSheet,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(48, 36),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'New Goal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonCard(height: 160),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: _goals.isEmpty
                  ? EmptyState(
                      emoji: '🎯',
                      title: 'No goals yet',
                      subtitle:
                          'Create your first savings goal stored right on your phone.',
                      action: ElevatedButton.icon(
                        onPressed: _showCreateGoalSheet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Goal'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(180, 48),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goals.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        return _GoalCard(
                          goal: _goals[i],
                          onContribute: () =>
                              _showContributeSheet(_goals[i]),
                          onDelete: () => _confirmDeleteGoal(_goals[i]),
                        );
                      },
                    ),
            ),
    );
  }

  void _showCreateGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateGoalSheet(
        onSave: (goal) async {
          await StorageService().saveSavingsGoal(goal);
          if (!sheetContext.mounted) return;
          Navigator.pop(sheetContext);
          _loadData();
        },
      ),
    );
  }

  void _showContributeSheet(SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ContributeSheet(
        goal: goal,
        onContribute: (amount) async {
          await StorageService().contributeToGoal(goal.id, amount);
          if (!sheetContext.mounted) return;
          Navigator.pop(sheetContext);
          _loadData();
        },
      ),
    );
  }

  void _confirmDeleteGoal(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService().deleteGoal(goal.id);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onContribute,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dt = goal.targetDate;
    final dateStr = '${dt.day} ${months[dt.month]} ${dt.year}';
    final remaining = goal.targetPaise - goal.savedPaise;
    final isCompleted = goal.isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.incomeGreen.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGreenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ Achieved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.incomeGreen,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.textLight),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete Goal',
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                'Target: $dateStr',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMedium),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatPaise(goal.savedPaise),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'of ${CurrencyFormatter.formatPaise(goal.targetPaise)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ),
              Text(
                '${(goal.progressRatio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              backgroundColor: AppColors.neutralGreyLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted
                    ? AppColors.incomeGreen
                    : AppColors.primary,
              ),
              minHeight: 10,
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 6),
            Text(
              '${CurrencyFormatter.formatPaise(remaining)} remaining',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: isCompleted ? null : onContribute,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                  isCompleted ? 'Goal Achieved 🎉' : 'Contribute'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGoalSheet extends StatefulWidget {
  final ValueChanged<SavingsGoal> onSave;
  const _CreateGoalSheet({required this.onSave});

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Savings Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal Title'),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Target amount is required';
                  final val = int.tryParse(v.replaceAll(',', ''));
                  if (val == null || val <= 0) {
                    return 'Enter a positive non-zero amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.textMedium),
                      const SizedBox(width: 10),
                      Text(
                        _targetDate == null
                            ? 'Select Target Date'
                            : '${_targetDate!.day} ${months[_targetDate!.month]} ${_targetDate!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _targetDate == null
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                        if (_targetDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a target date'),
                              backgroundColor: AppColors.expenseRed,
                            ),
                          );
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          final rupees = int.parse(
                              _targetController.text.replaceAll(',', ''));
                          widget.onSave(SavingsGoal(
                            id: 'g${DateTime.now().millisecondsSinceEpoch}',
                            title: _titleController.text.trim(),
                            targetPaise: rupees * 100,
                            savedPaise: 0,
                            targetDate: _targetDate!,
                          ));
                        }
                      },
                      child: const Text('Create Goal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  final SavingsGoal goal;
  final ValueChanged<int> onContribute;

  const _ContributeSheet(
      {required this.goal, required this.onContribute});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  String? _overTargetError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        widget.goal.targetPaise - widget.goal.savedPaise;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contribute to ${widget.goal.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Remaining: ${CurrencyFormatter.formatPaise(remaining)}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMedium),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                autofocus: true,
                onChanged: (_) =>
                    setState(() => _overTargetError = null),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final val = int.tryParse(v.replaceAll(',', ''));
                  if (val == null || val <= 0) {
                    return 'Enter a positive non-zero amount';
                  }
                  return null;
                },
              ),
              if (_overTargetError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _overTargetError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.expenseRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
                          final paise = rupees * 100;
                          if (paise > remaining) {
                            setState(() {
                              _overTargetError =
                                  'Amount exceeds remaining target of ${CurrencyFormatter.formatPaise(remaining)}. Adjust your contribution.';
                            });
                            return;
                          }
                          widget.onContribute(paise);
                        }
                      },
                      child: const Text('Contribute'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
