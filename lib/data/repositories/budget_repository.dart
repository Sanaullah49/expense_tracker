import '../database/database_helper.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(BudgetModel budget) async {
    return await _db.insertBudget(budget);
  }

  Future<List<BudgetModel>> getAll() async {
    return await _db.getAllBudgets();
  }

  Future<BudgetModel?> getById(String id) async {
    final budgets = await _db.getAllBudgets();
    try {
      return budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<BudgetModel>> getActive() async {
    return await _db.getActiveBudgets();
  }

  Future<List<BudgetModel>> getByCategory(String categoryId) async {
    final db = await _db.database;
    final result = await db.query(
      'budgets',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<List<BudgetModel>> getByPeriod(BudgetPeriod period) async {
    final db = await _db.database;
    final result = await db.query(
      'budgets',
      where: 'period = ?',
      whereArgs: [period.index],
    );
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<BudgetModel?> getActiveBudgetForCategory(String categoryId) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'budgets',
      where:
          'categoryId = ? AND isActive = 1 AND startDate <= ? AND endDate >= ?',
      whereArgs: [categoryId, now, now],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return BudgetModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<BudgetModel>> getExceeded() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT * FROM budgets 
      WHERE isActive = 1 
        AND endDate >= ? 
        AND spent > amount
    ''',
      [now],
    );
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<List<BudgetModel>> getNearLimit({int thresholdPercent = 80}) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT * FROM budgets 
      WHERE isActive = 1 
        AND endDate >= ? 
        AND spent <= amount
        AND (spent / amount * 100) >= ?
    ''',
      [now, thresholdPercent],
    );
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<int> update(BudgetModel budget) async {
    return await _db.updateBudget(budget);
  }

  Future<int> updateSpent(String id, double spent) async {
    return await _db.updateBudgetSpent(id, spent);
  }

  Future<void> addToSpent(String id, double amount) async {
    final budget = await getById(id);
    if (budget != null) {
      await updateSpent(id, budget.spent + amount);
    }
  }

  Future<void> subtractFromSpent(String id, double amount) async {
    final budget = await getById(id);
    if (budget != null) {
      final double newSpent = (budget.spent - amount).clamp(0, double.infinity);
      await updateSpent(id, newSpent);
    }
  }

  Future<void> setActive(String id, bool active) async {
    final db = await _db.database;
    await db.update(
      'budgets',
      {
        'isActive': active ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> resetSpent(String id) async {
    await updateSpent(id, 0);
  }

  Future<void> resetAllSpent() async {
    final db = await _db.database;
    await db.update('budgets', {
      'spent': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> delete(String id) async {
    return await _db.deleteBudget(id);
  }

  Future<int> deleteByCategory(String categoryId) async {
    final db = await _db.database;
    return await db.delete(
      'budgets',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> deleteInactive() async {
    final db = await _db.database;
    return await db.delete('budgets', where: 'isActive = ?', whereArgs: [0]);
  }

  Future<int> deleteExpired() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    return await db.delete('budgets', where: 'endDate < ?', whereArgs: [now]);
  }

  Future<int> deleteAll() async {
    final db = await _db.database;
    return await db.delete('budgets');
  }

  Future<double> getTotalBudgetAmount() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM budgets 
      WHERE isActive = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalSpent() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(spent), 0) as total 
      FROM budgets 
      WHERE isActive = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> getBudgetSummary() async {
    final totalBudget = await getTotalBudgetAmount();
    final totalSpent = await getTotalSpent();
    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRemaining': totalBudget - totalSpent,
      'percentUsed': totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0,
    };
  }

  Future<void> syncBudgetSpent(String budgetId) async {
    final budget = await getById(budgetId);
    if (budget == null) return;

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
    await updateSpent(budgetId, actualSpent);
  }

  Future<void> syncAllBudgetsSpent() async {
    final activeBudgets = await getActive();
    for (var budget in activeBudgets) {
      await syncBudgetSpent(budget.id);
    }
  }
}
