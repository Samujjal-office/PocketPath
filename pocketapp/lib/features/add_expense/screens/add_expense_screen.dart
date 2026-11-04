import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/transaction.dart';

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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return; // Prevent double-tap

    setState(() {
      _isSubmitting = true;
      _successMessage = null;
    });

    // Simulate offline save
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _successMessage =
          'Expense saved as Pending. Will sync automatically when online.';
    });

    // Reset form
    _formKey.currentState!.reset();
    _amountController.clear();
    _merchantController.clear();
    _noteController.clear();
    setState(() {
      _selectedCategory = TransactionCategory.food;
      _selectedDateTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Expense'),
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
                _buildOfflineNotice(),
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

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Amount'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _amountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
          decoration: const InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: AppColors.textLight,
            ),
            prefixText: '₹  ',
            prefixStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Category'),
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
              items: TransactionCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Text(c.emoji,
                          style: const TextStyle(fontSize: 18)),
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
        _FieldLabel('Merchant'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _merchantController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'e.g. Swiggy, Ola, Amazon…',
            prefixIcon: Icon(
              Icons.store_rounded,
              size: 20,
              color: AppColors.textMedium,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Merchant name is required';
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
        '${dt.day} ${months[dt.month]} ${dt.year},  '
        '${_pad(dt.hour)}:${_pad(dt.minute)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Date & Time'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      lastDate: DateTime.now(),
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
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Note (optional)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Add a note about this expense…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineNotice() {
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
            Icons.offline_bolt_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Works offline: Saved entries remain Pending until server confirmation.',
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
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(_isSubmitting ? 'Saving…' : 'Save Expense'),
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
          color: AppColors.incomeGreen.withOpacity(0.3),
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

