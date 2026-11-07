import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/transaction.dart';
import '../../../core/services/storage_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionDirection _direction = TransactionDirection.expense;
  TransactionCategory _selectedCategory = TransactionCategory.food;
  DateTime _selectedDateTime = DateTime.now();
  bool _isSubmitting = false;
  String? _successMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onDirectionChanged(TransactionDirection newDirection) {
    setState(() {
      _direction = newDirection;
      if (_direction == TransactionDirection.income) {
        _selectedCategory = TransactionCategory.salary;
      } else {
        _selectedCategory = TransactionCategory.food;
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return; // Prevent double-tap

    setState(() {
      _isSubmitting = true;
      _successMessage = null;
    });

    try {
      final amountValue = double.parse(_amountController.text.trim());
      final amountPaise = (amountValue * 100).round();
      final id = 'tx_${DateTime.now().millisecondsSinceEpoch}';

      final tx = Transaction(
        id: id,
        merchant: _merchantController.text.trim(),
        category: _selectedCategory,
        direction: _direction,
        amountPaise: amountPaise,
        dateTime: _selectedDateTime,
        status: TransactionStatus.synced,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      // Save into phone storage
      await StorageService().addTransaction(tx);

      if (!mounted) return;

      final formattedType = _direction == TransactionDirection.income ? 'Income' : 'Expense';
      final msg = '$formattedType of ₹${amountValue.toStringAsFixed(2)} saved to phone storage!';

      setState(() {
        _isSubmitting = false;
        _successMessage = msg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.incomeGreen,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/transactions');
            },
          ),
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _amountController.clear();
      _merchantController.clear();
      _noteController.clear();
      setState(() {
        _selectedCategory = _direction == TransactionDirection.income
            ? TransactionCategory.salary
            : TransactionCategory.food;
        _selectedDateTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: $e'),
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
        title: Text(_direction == TransactionDirection.income ? 'Add Income' : 'Add Expense'),
        backgroundColor: AppColors.background,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (_successMessage != null) ...[
                  _SuccessBanner(message: _successMessage!),
                  const SizedBox(height: 16),
                ],
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 16),
                _buildCategorySelector(),
                const SizedBox(height: 16),
                _buildMerchantField(),
                const SizedBox(height: 16),
                _buildDateTimePicker(),
                const SizedBox(height: 16),
                _buildNoteField(),
                const SizedBox(height: 24),
                _buildLocalStorageNotice(),
                const SizedBox(height: 20),
                _buildSaveButton(),
              ],
            ),
          ),
          // Submission locking overlay
          if (_isSubmitting)
            const ModalBarrier(
              dismissible: false,
              color: Colors.transparent,
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onDirectionChanged(TransactionDirection.expense),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _direction == TransactionDirection.expense
                      ? AppColors.expenseRed.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _direction == TransactionDirection.expense
                      ? Border.all(color: AppColors.expenseRed, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: _direction == TransactionDirection.expense
                          ? AppColors.expenseRed
                          : AppColors.textMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _direction == TransactionDirection.expense
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _direction == TransactionDirection.expense
                            ? AppColors.expenseRed
                            : AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _onDirectionChanged(TransactionDirection.income),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _direction == TransactionDirection.income
                      ? AppColors.incomeGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _direction == TransactionDirection.income
                      ? Border.all(color: AppColors.incomeGreen, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: _direction == TransactionDirection.income
                          ? AppColors.incomeGreen
                          : AppColors.textMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _direction == TransactionDirection.income
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _direction == TransactionDirection.income
                            ? AppColors.incomeGreen
                            : AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Amount'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: AppColors.textLight,
            ),
            prefixText: '₹  ',
            prefixStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _direction == TransactionDirection.income
                  ? AppColors.incomeGreen
                  : AppColors.primary,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Amount is required';
            final val = double.tryParse(v);
            if (val == null || val <= 0) {
              return 'Enter a valid positive amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    // Show categories appropriate for direction
    final categories = _direction == TransactionDirection.income
        ? [
            TransactionCategory.salary,
            TransactionCategory.investment,
            TransactionCategory.other,
          ]
        : [
            TransactionCategory.food,
            TransactionCategory.transport,
            TransactionCategory.shopping,
            TransactionCategory.entertainment,
            TransactionCategory.health,
            TransactionCategory.utilities,
            TransactionCategory.education,
            TransactionCategory.other,
          ];

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Category'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TransactionCategory>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMedium,
              ),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        c.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(_direction == TransactionDirection.income
            ? 'Source / Payer'
            : 'Merchant / Description'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _merchantController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: _direction == TransactionDirection.income
                ? 'e.g. Salary, Client payment, Freelancing…'
                : 'e.g. Swiggy, Ola, Amazon…',
            prefixIcon: Icon(
              _direction == TransactionDirection.income
                  ? Icons.account_balance_wallet_rounded
                  : Icons.store_rounded,
              size: 20,
              color: AppColors.textMedium,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Description is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dt = _selectedDateTime;
    final dateStr =
        '${dt.day} ${months[dt.month]} ${dt.year},  ${_pad(dt.hour)}:${_pad(dt.minute)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Date & Time'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 12),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.cardFill,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Note (optional)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Add a note about this transaction…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildLocalStorageNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.save_alt_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stored Locally: All data is securely stored on your phone storage. You can download and export statements at any time.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _direction == TransactionDirection.income
              ? AppColors.incomeGreen
              : AppColors.primary,
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_rounded, size: 20),
        label: Text(_isSubmitting
            ? 'Saving…'
            : _direction == TransactionDirection.income
                ? 'Save Income'
                : 'Save Expense'),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.incomeGreenLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.incomeGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.incomeGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.incomeGreen,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
