/// Formats integer paise values to INR display strings.
/// e.g. 24500 paise -> ₹245.00
/// e.g. 1234567 paise -> ₹12,345.67
class CurrencyFormatter {
  CurrencyFormatter._();

  static String formatPaise(int paise) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final rupees = absPaise ~/ 100;
    final cents = absPaise % 100;
    final formattedRupees = _formatWithCommas(rupees);
    final result = '₹$formattedRupees.${cents.toString().padLeft(2, '0')}';
    return isNegative ? '-$result' : result;
  }

  static String formatPaiseCompact(int paise) {
    final absPaise = paise.abs();
    final rupees = absPaise / 100;
    final isNegative = paise < 0;
    String result;
    if (rupees >= 10000000) {
      result = '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
    } else if (rupees >= 100000) {
      result = '₹${(rupees / 100000).toStringAsFixed(1)}L';
    } else if (rupees >= 1000) {
      result = '₹${(rupees / 1000).toStringAsFixed(1)}K';
    } else {
      result = '₹${rupees.toStringAsFixed(2)}';
    }
    return isNegative ? '-$result' : result;
  }

  static String _formatWithCommas(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final len = s.length;
    // Indian number formatting: last 3 digits, then groups of 2
    if (len <= 3) return s;
    final last3 = s.substring(len - 3);
    final rest = s.substring(0, len - 3);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = rest.length - 1; i >= 0; i--) {
      if (count > 0 && count % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()},$last3';
  }
}
