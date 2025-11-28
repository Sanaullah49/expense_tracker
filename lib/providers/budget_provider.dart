import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/services/notification_service.dart';
import '../data/database/database_helper.dart';
import '../data/models/budget_model.dart';

class BudgetProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();
  final _notificationService = NotificationService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<BudgetModel> get budgets => List.unmodifiable(_budgets);

  List<BudgetModel> get activeBudgets =>
      _budgets.where((b) => b.isActive && !_isExpired(b)).toList();

  List<BudgetModel> get expiredBudgets =>
      _budgets.where((b) => _isExpired(b)).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBudget => activeBudgets.fold(0, (sum, b) => sum + b.amount);
  double get totalSpent => activeBudgets.fold(0, (sum, b) => sum + b.spent);
  double get totalRemaining => totalBudget - totalSpent;

  double get overallPercentUsed =>
      totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;

  bool _isExpired(BudgetModel budget) {
    return DateTime.now().isAfter(budget.endDate);
  }

  Future<void> loadBudgets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _budgets = await _db.getAllBudgets();
      await _autoRenewBudgets();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading budgets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _autoRenewBudgets() async {
    for (var budget in _budgets) {
      if (_isExpired(budget) &&
          budget.isActive &&
          budget.period != BudgetPeriod.custom) {
        await _renewBudget(budget);
      }
    }
  }

  Future<void> _renewBudget(BudgetModel budget) async {
    final now = DateTime.now();
    DateTime newStart;
    DateTime newEnd;

    switch (budget.period) {
      case BudgetPeriod.daily:
        newStart = DateTime(now.year, now.month, now.day);
        newEnd = newStart
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        break;
      case BudgetPeriod.weekly:
        newStart = now.subtract(Duration(days: now.weekday - 1));
        newStart = DateTime(newStart.year, newStart.month, newStart.day);
        newEnd = newStart
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
        break;
      case BudgetPeriod.monthly:
        newStart = DateTime(now.year, now.month, 1);
        newEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case BudgetPeriod.yearly:
        newStart = DateTime(now.year, 1, 1);
        newEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        return;
    }

    final renewedBudget = budget.copyWith(
      startDate: newStart,
      endDate: newEnd,
      spent: 0,
    );

    await _db.updateBudget(renewedBudget);

    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = renewedBudget;
    }
  }

  Future<bool> addBudget(BudgetModel budget) async {
    try {
      final newBudget = BudgetModel(
        id: _uuid.v4(),
        name: budget.name,
        amount: budget.amount,
        categoryId: budget.categoryId,
        period: budget.period,
        startDate: budget.startDate,
        endDate: budget.endDate,
        notifyOnExceed: budget.notifyOnExceed,
        notifyAtPercent: budget.notifyAtPercent,
      );

      await _db.insertBudget(newBudget);
      _budgets.add(newBudget);

      await recalculateBudgetSpent(newBudget.id);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding budget: $e');
      return false;
    }
  }

  Future<bool> updateBudget(BudgetModel budget) async {
    try {
      await _db.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
        await recalculateBudgetSpent(budget.id);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating budget: $e');
      return false;
    }
  }

  Future<void> recalculateCategoryBudgets(String categoryId) async {
    try {
      final matchingBudgetIds = _budgets
          .where(
            (b) => b.categoryId == categoryId && b.isActive && !_isExpired(b),
          )
          .map((b) => b.id)
          .toList();

      for (var budgetId in matchingBudgetIds) {
        await recalculateBudgetSpent(budgetId);
      }
    } catch (e) {
      debugPrint('Error recalculating category budgets: $e');
    }
  }

  Future<void> recalculateBudgetSpent(String budgetId) async {
    try {
      final index = _budgets.indexWhere((b) => b.id == budgetId);
      if (index == -1) return;

      final budget = _budgets[index];

      final db = await _db.database;

      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM transactions
        WHERE categoryId = ?
          AND type = 1
          AND date BETWEEN ? AND ?
        ''',
        [
          budget.categoryId,
          budget.startDate.toIso8601String(),
          budget.endDate.toIso8601String(),
        ],
      );

      final actualSpent = (result.first['total'] as num?)?.toDouble() ?? 0;

      debugPrint('Recalculated budget "${budget.name}": $actualSpent');

      await _db.updateBudgetSpent(budgetId, actualSpent);

      final updatedBudget = budget.copyWith(spent: actualSpent);
      _budgets[index] = updatedBudget;

      await _checkBudgetAlerts(updatedBudget);
      notifyListeners();
    } catch (e) {
      debugPrint('Error recalculating budget: $e');
    }
  }

  Future<bool> updateBudgetSpent(
    String categoryId,
    double amount, {
    bool subtract = false,
  }) async {
    await recalculateCategoryBudgets(categoryId);
    return true;
  }

  Future<void> _checkBudgetAlerts(BudgetModel budget) async {
    if (!budget.notifyOnExceed) return;

    if (budget.isExceeded) {
      await _notificationService.showBudgetAlert(
        budgetName: budget.name,
        percentUsed: 100,
        exceeded: true,
      );
    } else if (budget.isNearLimit) {
      await _notificationService.showBudgetAlert(
        budgetName: budget.name,
        percentUsed: budget.percentUsed,
        exceeded: false,
      );
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await _db.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting budget: $e');
      return false;
    }
  }

  Future<bool> toggleBudgetActive(String id) async {
    try {
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index == -1) return false;

      final budget = _budgets[index];
      final updated = budget.copyWith(isActive: !budget.isActive);

      await _db.updateBudget(updated);
      _budgets[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> resetBudget(String id) async {
    try {
      await _db.updateBudgetSpent(id, 0);
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        _budgets[index] = _budgets[index].copyWith(spent: 0);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  BudgetModel? getBudgetById(String id) {
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  List<BudgetModel> getBudgetsByCategory(String categoryId) {
    return _budgets.where((b) => b.categoryId == categoryId).toList();
  }

  List<BudgetModel> getExceededBudgets() {
    return activeBudgets.where((b) => b.isExceeded).toList();
  }

  List<BudgetModel> getNearLimitBudgets() {
    return activeBudgets.where((b) => b.isNearLimit && !b.isExceeded).toList();
  }

  BudgetHealthStatus getBudgetHealth() {
    if (activeBudgets.isEmpty) return BudgetHealthStatus.noBudgets;

    final exceededCount = getExceededBudgets().length;
    final nearLimitCount = getNearLimitBudgets().length;

    if (exceededCount > 0) return BudgetHealthStatus.exceeded;
    if (nearLimitCount > 0) return BudgetHealthStatus.warning;
    return BudgetHealthStatus.healthy;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

enum BudgetHealthStatus { noBudgets, healthy, warning, exceeded }

extension BudgetHealthStatusExtension on BudgetHealthStatus {
  String get message {
    switch (this) {
      case BudgetHealthStatus.noBudgets:
        return 'No active budgets';
      case BudgetHealthStatus.healthy:
        return 'All budgets on track';
      case BudgetHealthStatus.warning:
        return 'Some budgets near limit';
      case BudgetHealthStatus.exceeded:
        return 'Budget exceeded!';
    }
  }

  IconData get icon {
    switch (this) {
      case BudgetHealthStatus.noBudgets:
        return Icons.account_balance_wallet_outlined;
      case BudgetHealthStatus.healthy:
        return Icons.check_circle;
      case BudgetHealthStatus.warning:
        return Icons.warning;
      case BudgetHealthStatus.exceeded:
        return Icons.error;
    }
  }
}
