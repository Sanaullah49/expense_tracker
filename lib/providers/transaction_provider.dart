import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_range_presets.dart';
import '../data/database/database_helper.dart';
import '../data/models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;
  String? _error;

  DateTime? _startDate;
  DateTime? _endDate;
  TransactionDateRangePreset _selectedDateRangePreset =
      TransactionDateRangePreset.allData;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  TransactionType? _selectedType;
  String _searchQuery = '';

  TransactionSortType _sortType = TransactionSortType.dateDesc;

  List<TransactionModel> get transactions => _filteredTransactions;
  List<TransactionModel> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TransactionDateRangePreset get selectedDateRangePreset =>
      _selectedDateRangePreset;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedAccountId => _selectedAccountId;
  TransactionType? get selectedType => _selectedType;
  TransactionSortType get sortType => _sortType;
  bool get hasFilters =>
      _startDate != null ||
      _endDate != null ||
      _selectedCategoryId != null ||
      _selectedAccountId != null ||
      _selectedType != null ||
      _searchQuery.isNotEmpty;

  double _cachedTotalIncome = 0;
  double _cachedTotalExpense = 0;

  double get totalIncome => _cachedTotalIncome;
  double get totalExpense => _cachedTotalExpense;

  double get balance => totalIncome - totalExpense;

  int get transactionCount => _filteredTransactions.length;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _db.getAllTransactions();
      _applyFiltersAndSort();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final newTransaction = TransactionModel(
        id: _uuid.v4(),
        title: transaction.title,
        amount: transaction.amount,
        type: transaction.type,
        categoryId: transaction.categoryId,
        accountId: transaction.accountId,
        toAccountId: transaction.toAccountId,
        date: transaction.date,
        note: transaction.note,
        receiptImage: transaction.receiptImage,
        isRecurring: transaction.isRecurring,
        recurringId: transaction.recurringId,
      );

      await _db.insertTransaction(newTransaction);
      _transactions.insert(0, newTransaction);
      _applyFiltersAndSort();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding transaction: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      final updatedTransaction = transaction.copyWith();
      await _db.updateTransaction(updatedTransaction);

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _applyFiltersAndSort();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating transaction: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _db.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _applyFiltersAndSort();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting transaction: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMultipleTransactions(List<String> ids) async {
    try {
      for (final id in ids) {
        await _db.deleteTransaction(id);
      }
      _transactions.removeWhere((t) => ids.contains(t.id));
      _applyFiltersAndSort();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting transactions: $e');
      notifyListeners();
      return false;
    }
  }

  TransactionModel? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  void setDateRange(
    DateTime start,
    DateTime end, {
    TransactionDateRangePreset preset = TransactionDateRangePreset.custom,
  }) {
    _startDate = _normalizeStartDate(start);
    _endDate = _normalizeEndDate(end);
    _selectedDateRangePreset = preset;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void applyFilters({
    TransactionType? type,
    DateTimeRange? dateRange,
    TransactionDateRangePreset dateRangePreset =
        TransactionDateRangePreset.allData,
  }) {
    _selectedType = type;
    _selectedDateRangePreset = dateRangePreset;

    if (dateRange != null) {
      _startDate = _normalizeStartDate(dateRange.start);
      _endDate = _normalizeEndDate(dateRange.end);
    } else {
      _startDate = null;
      _endDate = null;
    }

    _applyFiltersAndSort();
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setAccount(String? accountId) {
    _selectedAccountId = accountId;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setType(TransactionType? type) {
    _selectedType = type;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortType(TransactionSortType sortType) {
    _sortType = sortType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _selectedDateRangePreset = TransactionDateRangePreset.allData;
    _selectedCategoryId = null;
    _selectedAccountId = null;
    _selectedType = null;
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    _filteredTransactions = _transactions.where((t) {
      if (_startDate != null && t.date.isBefore(_startDate!)) return false;
      if (_endDate != null && t.date.isAfter(_endDate!)) {
        return false;
      }

      if (_selectedCategoryId != null && t.categoryId != _selectedCategoryId) {
        return false;
      }

      if (_selectedAccountId != null &&
          t.accountId != _selectedAccountId &&
          t.toAccountId != _selectedAccountId) {
        return false;
      }

      if (_selectedType != null && t.type != _selectedType) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!t.title.toLowerCase().contains(query) &&
            !(t.note?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      return true;
    }).toList();

    _filteredTransactions.sort((a, b) {
      switch (_sortType) {
        case TransactionSortType.dateDesc:
          return b.date.compareTo(a.date);
        case TransactionSortType.dateAsc:
          return a.date.compareTo(b.date);
        case TransactionSortType.amountDesc:
          return b.amount.compareTo(a.amount);
        case TransactionSortType.amountAsc:
          return a.amount.compareTo(b.amount);
        case TransactionSortType.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case TransactionSortType.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });

    _cachedTotalIncome = _filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    _cachedTotalExpense = _filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<DateTime, List<TransactionModel>> getTransactionsGroupedByDate() {
    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (var transaction in _filteredTransactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(transaction);
      } else {
        grouped[date] = [transaction];
      }
    }

    return grouped;
  }

  Map<String, List<TransactionModel>> getTransactionsGroupedByCategory() {
    final Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in _filteredTransactions) {
      if (grouped.containsKey(transaction.categoryId)) {
        grouped[transaction.categoryId]!.add(transaction);
      } else {
        grouped[transaction.categoryId] = [transaction];
      }
    }

    return grouped;
  }

  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  List<TransactionModel> getTransactionsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = _normalizeStartDate(start);
    final normalizedEnd = _normalizeEndDate(end);

    return _transactions.where((t) {
      return !t.date.isBefore(normalizedStart) &&
          !t.date.isAfter(normalizedEnd);
    }).toList();
  }

  DateTime _normalizeStartDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _normalizeEndDate(DateTime date) {
    final hasTime =
        date.hour != 0 ||
        date.minute != 0 ||
        date.second != 0 ||
        date.millisecond != 0 ||
        date.microsecond != 0;

    if (hasTime) return date;
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);
  }

  Map<String, double> getCategoryTotals({DateTime? start, DateTime? end}) {
    final transactions = start != null && end != null
        ? getTransactionsForDateRange(start, end)
        : _transactions;

    final Map<String, double> totals = {};

    for (var t in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }

    return totals;
  }

  Map<DateTime, Map<String, double>> getDailyTotals({int days = 7}) {
    final Map<DateTime, Map<String, double>> dailyTotals = {};
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailyTotals[date] = {'income': 0, 'expense': 0};
    }

    for (var t in _transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      if (dailyTotals.containsKey(date)) {
        if (t.type == TransactionType.income) {
          dailyTotals[date]!['income'] =
              dailyTotals[date]!['income']! + t.amount;
        } else if (t.type == TransactionType.expense) {
          dailyTotals[date]!['expense'] =
              dailyTotals[date]!['expense']! + t.amount;
        }
      }
    }

    return dailyTotals;
  }

  Map<int, Map<String, double>> getMonthlyTotals({int year = 0}) {
    final targetYear = year == 0 ? DateTime.now().year : year;
    final Map<int, Map<String, double>> monthlyTotals = {};

    for (int month = 1; month <= 12; month++) {
      monthlyTotals[month] = {'income': 0, 'expense': 0};
    }

    for (var t in _transactions.where((t) => t.date.year == targetYear)) {
      final month = t.date.month;
      if (t.type == TransactionType.income) {
        monthlyTotals[month]!['income'] =
            monthlyTotals[month]!['income']! + t.amount;
      } else if (t.type == TransactionType.expense) {
        monthlyTotals[month]!['expense'] =
            monthlyTotals[month]!['expense']! + t.amount;
      }
    }

    return monthlyTotals;
  }

  double getAverageExpense({DateTime? start, DateTime? end}) {
    final expenses = start != null && end != null
        ? getTransactionsForDateRange(
            start,
            end,
          ).where((t) => t.type == TransactionType.expense).toList()
        : _transactions
              .where((t) => t.type == TransactionType.expense)
              .toList();

    if (expenses.isEmpty) return 0;
    return expenses.fold<double>(0, (sum, t) => sum + t.amount) /
        expenses.length;
  }

  TransactionModel? getLargestExpense({DateTime? start, DateTime? end}) {
    final expenses = start != null && end != null
        ? getTransactionsForDateRange(
            start,
            end,
          ).where((t) => t.type == TransactionType.expense).toList()
        : _transactions
              .where((t) => t.type == TransactionType.expense)
              .toList();

    if (expenses.isEmpty) return null;
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.first;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

enum TransactionSortType {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  titleAsc,
  titleDesc,
}

extension TransactionSortTypeExtension on TransactionSortType {
  String get label {
    switch (this) {
      case TransactionSortType.dateDesc:
        return 'Date (Newest First)';
      case TransactionSortType.dateAsc:
        return 'Date (Oldest First)';
      case TransactionSortType.amountDesc:
        return 'Amount (High to Low)';
      case TransactionSortType.amountAsc:
        return 'Amount (Low to High)';
      case TransactionSortType.titleAsc:
        return 'Title (A-Z)';
      case TransactionSortType.titleDesc:
        return 'Title (Z-A)';
    }
  }
}
