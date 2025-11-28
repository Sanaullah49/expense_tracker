import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../constants/app_colors.dart';

class Helpers {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  static DateTimeRange getDateRange(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period.toLowerCase()) {
      case 'today':
        return DateTimeRange(
          start: today,
          end: today
              .add(const Duration(days: 1))
              .subtract(const Duration(microseconds: 1)),
        );
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: yesterday,
          end: today.subtract(const Duration(microseconds: 1)),
        );
      case 'this week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: now);
      case 'last week':
        final startOfLastWeek = today.subtract(
          Duration(days: today.weekday + 6),
        );
        final endOfLastWeek = today.subtract(Duration(days: today.weekday));
        return DateTimeRange(
          start: startOfLastWeek,
          end: endOfLastWeek.subtract(const Duration(microseconds: 1)),
        );
      case 'this month':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case 'last month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: lastMonth,
          end: DateTime(
            now.year,
            now.month,
            1,
          ).subtract(const Duration(microseconds: 1)),
        );
      case 'this year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case 'last year':
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(
            now.year,
            1,
            1,
          ).subtract(const Duration(microseconds: 1)),
        );
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  static Color getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  static IconData getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  static Color getBudgetStatusColor(BudgetModel budget) {
    if (budget.isExceeded) {
      return AppColors.error;
    } else if (budget.isNearLimit) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total * 100).clamp(0, 100);
  }

  static Color getRandomCategoryColor() {
    final random = math.Random();
    return AppColors.categoryColors[random.nextInt(
      AppColors.categoryColors.length,
    )];
  }

  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }

  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }

  static Function(T) debounce<T>(Duration duration, Function(T) callback) {
    DateTime? lastCall;
    return (T args) {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) > duration) {
        lastCall = now;
        callback(args);
      }
    };
  }

  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static String generateId() {
    final now = DateTime.now();
    final random = math.Random();
    return '${now.millisecondsSinceEpoch}_${random.nextInt(999999)}';
  }

  static double? parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  static IconData getAccountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.account_balance_wallet;
      case 'bank':
        return Icons.account_balance;
      case 'credit card':
      case 'creditcard':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  static String getBudgetPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Daily';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.custom:
        return 'Custom';
    }
  }

  static DateTimeRange getBudgetPeriodDates(BudgetPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.daily:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case BudgetPeriod.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day + 6,
            23,
            59,
            59,
          ),
        );
      case BudgetPeriod.monthly:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case BudgetPeriod.yearly:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case BudgetPeriod.custom:
        return DateTimeRange(
          start: now,
          end: now.add(const Duration(days: 30)),
        );
    }
  }

  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}
