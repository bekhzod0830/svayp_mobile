/// String Extensions and Utilities
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String capitalizeEachWord() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number (Uzbekistan)
  bool get isValidUzbekPhone {
    final phoneRegex = RegExp(r'^998[0-9]{9}$');
    return phoneRegex.hasMatch(replaceAll(RegExp(r'[^\d]'), ''));
  }

  /// Check if string is a valid name
  bool get isValidName {
    return trim().isNotEmpty && trim().length >= 2;
  }

  /// Remove all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

/// Number Extensions
extension IntExtensions on int {
  /// Format number with thousand separators
  String formatWithSeparator([String separator = ' ']) {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}$separator',
    );
  }

  /// Convert UZS to USD (approximate)
  double toUsd([double rate = 12500.0]) {
    return this / rate;
  }
}

extension DoubleExtensions on double {
  /// Round to decimal places
  double roundToDecimal(int places) {
    final mod = 10.0 * places;
    return (this * mod).round() / mod;
  }
}

/// Currency Formatter
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format UZS currency
  static String formatUzs(int amount, {bool showCurrency = true}) {
    final formatted = amount.formatWithSeparator(' ');
    return showCurrency ? '$formatted UZS' : formatted;
  }

  /// Format USD currency
  static String formatUsd(double amount, {bool showCurrency = true}) {
    final formatted = amount.toStringAsFixed(2);
    return showCurrency ? '\$$formatted' : formatted;
  }

  /// Format with both currencies
  static String formatBoth(int uzsAmount) {
    final uzs = formatUzs(uzsAmount);
    final usd = formatUsd(uzsAmount.toUsd());
    return '$uzs (~$usd)';
  }
}

/// Date Formatter
class DateFormatter {
  DateFormatter._();

  /// Format date to readable string
  static String format(DateTime date, {String format = 'dd MMM yyyy'}) {
    // Simple implementation - can be enhanced with intl package
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    return '$day $month $year';
  }

  /// Get time ago string
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
