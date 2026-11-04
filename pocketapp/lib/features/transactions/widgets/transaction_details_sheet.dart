import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/models/transaction.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.direction == TransactionDirection.income;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dt = transaction.dateTime;
    final dateStr =
        '${dt.day} ${months[dt.month]} ${dt.year}, ${_pad(dt.hour)}:${_pad(dt.minute)}';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (transaction.status) {
      case TransactionStatus.pending:
        statusColor = AppColors.warningOchre;
        statusLabel = 'Pending';
        statusIcon = Icons.schedule_rounded;
        break;
      case TransactionStatus.failed:
        statusColor = AppColors.expenseRed;
        statusLabel = 'Failed (Network)';
        statusIcon = Icons.wifi_off_rounded;
        break;
      case TransactionStatus.synced:
        statusColor = AppColors.incomeGreen;
        statusLabel = 'Synced';
        statusIcon = Icons.cloud_done_rounded;
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Amount header
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.incomeGreenLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  transaction.category.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              transaction.merchant,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.formatPaise(transaction.amountPaise)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isIncome
                    ? AppColors.incomeGreen
                    : AppColors.expenseRed,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Category',
                    value:
                        '${transaction.category.emoji}  ${transaction.category.displayName}',
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _DetailRow(label: 'Date & Time', value: dateStr),
                  const Divider(height: 24, color: AppColors.border),
                  _DetailRow(
                    label: 'Direction',
                    value: isIncome ? 'Income' : 'Expense',
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (transaction.note != null) ...[
                    const Divider(height: 24, color: AppColors.border),
                    _DetailRow(
                        label: 'Note', value: transaction.note!),
                  ],
                  if (transaction.status == TransactionStatus.failed) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.expenseRedLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.expenseRed),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This transaction failed to sync due to a network error and will be retried automatically.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.expenseRed,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
