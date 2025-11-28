import 'package:intl/intl.dart';

class Formatters {
  static String currency(
    double amount, {
    String symbol = '\$',
    int decimalDigits = 2,
    String locale = 'en_US',
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String compactCurrency(
    double amount, {
    String symbol = '\$',
    String locale = 'en_US',
  }) {
    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      symbol: symbol,
    );
    return formatter.format(amount);
  }

  static String simpleCurrency(double amount, {String symbol = '\$'}) {
    if (amount < 0) {
      return '-$symbol${amount.abs().toStringAsFixed(2)}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String number(double value, {int decimalDigits = 0}) {
    final formatter = NumberFormat.decimalPattern();
    if (decimalDigits > 0) {
      return value.toStringAsFixed(decimalDigits);
    }
    return formatter.format(value);
  }

  static String compact(double value) {
    final formatter = NumberFormat.compact();
    return formatter.format(value);
  }

  static String percentage(double value, {int decimalDigits = 1}) {
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  static String date(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String time(DateTime date, {bool use24Hour = false}) {
    return DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(date);
  }

  static String dateTime(DateTime date, {bool use24Hour = false}) {
    final dateStr = DateFormat('MMM dd, yyyy').format(date);
    final timeStr = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(date);
    return '$dateStr at $timeStr';
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else if (difference > 0 && difference < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  static String relativeDateWithTime(DateTime date, {bool use24Hour = false}) {
    final relDate = relativeDate(date);
    final timeStr = time(date, use24Hour: use24Hour);
    return '$relDate, $timeStr';
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String shortMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String dayOfWeek(DateTime date, {bool short = false}) {
    return DateFormat(short ? 'E' : 'EEEE').format(date);
  }

  static String monthDay(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String duration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  static String phoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String ordinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  static String initials(String name, {int maxInitials = 2}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(maxInitials)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();
    return initials;
  }

  static String truncateName(String name, {int maxLength = 20}) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 3)}...';
  }
}
