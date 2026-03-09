import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionDateRangePreset {
  oneWeek,
  twoWeeks,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  fiscalYear,
  custom,
  allData,
}

class DateRangePresetHelper {
  static const int fiscalYearStartMonth = 7;

  static const List<TransactionDateRangePreset> presets = [
    TransactionDateRangePreset.oneWeek,
    TransactionDateRangePreset.twoWeeks,
    TransactionDateRangePreset.oneMonth,
    TransactionDateRangePreset.threeMonths,
    TransactionDateRangePreset.sixMonths,
    TransactionDateRangePreset.oneYear,
    TransactionDateRangePreset.fiscalYear,
    TransactionDateRangePreset.custom,
    TransactionDateRangePreset.allData,
  ];

  static String chipLabel(TransactionDateRangePreset preset) {
    switch (preset) {
      case TransactionDateRangePreset.oneWeek:
        return '1 Week';
      case TransactionDateRangePreset.twoWeeks:
        return '2 Weeks';
      case TransactionDateRangePreset.oneMonth:
        return '1 Month';
      case TransactionDateRangePreset.threeMonths:
        return '3 Months';
      case TransactionDateRangePreset.sixMonths:
        return '6 Months';
      case TransactionDateRangePreset.oneYear:
        return '1 Year';
      case TransactionDateRangePreset.fiscalYear:
        return 'Fiscal Year';
      case TransactionDateRangePreset.custom:
        return 'Custom';
      case TransactionDateRangePreset.allData:
        return 'All Data';
    }
  }

  static DateTimeRange? resolveRange(
    TransactionDateRangePreset preset, {
    DateTime? now,
    DateTimeRange? customRange,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    switch (preset) {
      case TransactionDateRangePreset.oneWeek:
        return _dayRange(today.subtract(const Duration(days: 6)), today);
      case TransactionDateRangePreset.twoWeeks:
        return _dayRange(today.subtract(const Duration(days: 13)), today);
      case TransactionDateRangePreset.oneMonth:
        return _dayRange(_subtractMonthsClamped(today, 1), today);
      case TransactionDateRangePreset.threeMonths:
        return _dayRange(_subtractMonthsClamped(today, 3), today);
      case TransactionDateRangePreset.sixMonths:
        return _dayRange(_subtractMonthsClamped(today, 6), today);
      case TransactionDateRangePreset.oneYear:
        return _dayRange(_subtractMonthsClamped(today, 12), today);
      case TransactionDateRangePreset.fiscalYear:
        final fiscalYearStart = today.month >= fiscalYearStartMonth
            ? DateTime(today.year, fiscalYearStartMonth, 1)
            : DateTime(today.year - 1, fiscalYearStartMonth, 1);
        return _dayRange(fiscalYearStart, today);
      case TransactionDateRangePreset.custom:
        if (customRange == null) return null;
        return _dayRange(customRange.start, customRange.end);
      case TransactionDateRangePreset.allData:
        return null;
    }
  }

  static DateTimeRange? allDataRange(Iterable<DateTime> dates) {
    if (dates.isEmpty) return null;

    DateTime? earliest;
    DateTime? latest;
    for (final date in dates) {
      if (earliest == null || date.isBefore(earliest)) {
        earliest = date;
      }
      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }

    if (earliest == null || latest == null) return null;
    return _dayRange(earliest, latest);
  }

  static String describeSelection(
    TransactionDateRangePreset preset,
    DateTimeRange? range,
  ) {
    if (preset == TransactionDateRangePreset.allData) {
      return 'All Data';
    }

    if (range == null) {
      return chipLabel(preset);
    }

    return '${DateFormat('MMM d, yyyy').format(range.start)} - '
        '${DateFormat('MMM d, yyyy').format(range.end)}';
  }

  static DateTimeRange _dayRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
      999,
    );
    return DateTimeRange(start: normalizedStart, end: normalizedEnd);
  }

  static DateTime _subtractMonthsClamped(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 - months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = math.min(date.day, DateUtils.getDaysInMonth(year, month));
    return DateTime(year, month, day);
  }
}
