import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MonthSelectorDropdown extends StatelessWidget {
  final String selectedMonth;
  final List<String> months;
  final ValueChanged<String?> onChanged;

  const MonthSelectorDropdown({
    super.key,
    required this.selectedMonth,
    required this.months,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validSelectedMonth =
        months.contains(selectedMonth) ? selectedMonth : months.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryContainer, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validSelectedMonth,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.primaryDark,
          ),
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: months.map((m) {
            return DropdownMenuItem<String>(
              value: m,
              child: Text(m),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

String getCurrentMonthString() {
  final now = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[now.month - 1]} ${now.year}';
}

DateTime parseMonthYear(String monthStr) {
  final parts = monthStr.split(' ');
  if (parts.length == 2) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final mIndex = months.indexOf(parts[0]);
    final year = int.tryParse(parts[1]);
    if (mIndex != -1 && year != null) {
      return DateTime(year, mIndex + 1);
    }
  }
  return DateTime.now();
}

final List<String> kMonthOptions = [
  'January 2026',
  'February 2026',
  'March 2026',
  'April 2026',
  'May 2026',
  'June 2026',
  'July 2026',
  'August 2026',
  'September 2026',
  'October 2026',
  'November 2026',
  'December 2026',
];
