import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 6;
  }

  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

extension NullableStringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  String orEmpty() => this ?? '';
}

extension DateTimeExtension on DateTime {
  String get formatted => DateFormat('MMM dd, yyyy').format(this);
  String get formattedWithTime => DateFormat('MMM dd, yyyy HH:mm').format(this);
  String get formattedTime => DateFormat('HH:mm').format(this);
  String get formattedDate => DateFormat('yyyy-MM-dd').format(this);
  String get dayName => DateFormat('EEEE').format(this);
  String get shortDayName => DateFormat('E').format(this);
  String get monthName => DateFormat('MMMM').format(this);
  String get shortMonthName => DateFormat('MMM').format(this);
  String get yearMonth => DateFormat('MMMM yyyy').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isThisYear {
    return year == DateTime.now().year;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  DateTime get startOfYear => DateTime(year, 1, 1);
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

extension DoubleExtension on double {
  String toMoney({String symbol = '\$', int decimals = 2}) {
    return '$symbol${toStringAsFixed(decimals)}';
  }

  String toCompactMoney({String symbol = '\$'}) {
    if (abs() >= 1000000000) {
      return '$symbol${(this / 1000000000).toStringAsFixed(1)}B';
    } else if (abs() >= 1000000) {
      return '$symbol${(this / 1000000).toStringAsFixed(1)}M';
    } else if (abs() >= 1000) {
      return '$symbol${(this / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${toStringAsFixed(2)}';
  }

  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  double roundTo(int places) {
    double mod = 10.0 * places;
    return ((this * mod).round().toDouble() / mod);
  }
}

extension IntExtension on int {
  String get ordinal {
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }

  Duration get days => Duration(days: this);
  Duration get hours => Duration(hours: this);
  Duration get minutes => Duration(minutes: this);
  Duration get seconds => Duration(seconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  List<T> takeLast(int n) {
    if (n >= length) return this;
    return sublist(length - n);
  }

  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    return fold<Map<K, List<T>>>({}, (map, element) {
      final key = keyFunction(element);
      map.putIfAbsent(key, () => []).add(element);
      return map;
    });
  }

  double sumBy(double Function(T) selector) {
    return fold(0.0, (sum, element) => sum + selector(element));
  }
}

extension TransactionListExtension on List<TransactionModel> {
  double get totalIncome {
    return where(
      (t) => t.type == TransactionType.income,
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return where(
      (t) => t.type == TransactionType.expense,
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  Map<DateTime, List<TransactionModel>> groupByDate() {
    return groupBy((t) => DateTime(t.date.year, t.date.month, t.date.day));
  }

  Map<String, List<TransactionModel>> groupByCategory() {
    return groupBy((t) => t.categoryId);
  }

  Map<String, double> categoryTotals() {
    final Map<String, double> totals = {};
    for (var t in this) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    return totals;
  }
}

extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  double get bottomBarHeight => MediaQuery.of(this).padding.bottom;

  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  Future<T?> pushReplacement<T>(Widget page) => Navigator.of(
    this,
  ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  void popUntilFirst() => Navigator.of(this).popUntil((route) => route.isFirst);

  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  Future<T?> showCustomDialog<T>(Widget dialog) {
    return showDialog<T>(context: this, builder: (_) => dialog);
  }

  Future<T?> showBottomSheet<T>(Widget sheet) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      builder: (_) => sheet,
    );
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String get formatted {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formatted12Hour {
    final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final p = period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  DateTime toDateTime([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, hour, minute);
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
