import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(TransactionModel transaction) async {
    return await _db.insertTransaction(transaction);
  }

  Future<List<TransactionModel>> getAll() async {
    return await _db.getAllTransactions();
  }

  Future<TransactionModel?> getById(String id) async {
    final transactions = await _db.getAllTransactions();
    try {
      return transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<TransactionModel>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getTransactionsByDateRange(start, end);
  }

  Future<List<TransactionModel>> getByCategory(String categoryId) async {
    return await _db.getTransactionsByCategory(categoryId);
  }

  Future<List<TransactionModel>> getByAccount(String accountId) async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      where: 'accountId = ? OR toAccountId = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getByType(TransactionType type) async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getRecent({int limit = 10}) async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> search(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'transactions',
      where: 'title LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> update(TransactionModel transaction) async {
    return await _db.updateTransaction(transaction);
  }

  Future<int> delete(String id) async {
    return await _db.deleteTransaction(id);
  }

  Future<int> deleteByCategory(String categoryId) async {
    final db = await _db.database;
    return await db.delete(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> deleteByAccount(String accountId) async {
    final db = await _db.database;
    return await db.delete(
      'transactions',
      where: 'accountId = ? OR toAccountId = ?',
      whereArgs: [accountId, accountId],
    );
  }

  Future<int> deleteAll() async {
    final db = await _db.database;
    return await db.delete('transactions');
  }

  Future<Map<String, double>> getTotalsByType(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getTotalsByType(start, end);
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getExpensesByCategory(start, end);
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getDailyTotals(start, end);
  }

  Future<double> getTotalIncome({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    String query =
        'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 0';
    List<dynamic> args = [];

    if (start != null && end != null) {
      query += ' AND date BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpense({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    String query =
        'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 1';
    List<dynamic> args = [];

    if (start != null && end != null) {
      query += ' AND date BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTransactionCount({TransactionType? type}) async {
    final db = await _db.database;
    String query = 'SELECT COUNT(*) as count FROM transactions';
    List<dynamic> args = [];

    if (type != null) {
      query += ' WHERE type = ?';
      args = [type.index];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getAverageExpense({DateTime? start, DateTime? end}) async {
    final db = await _db.database;
    String query =
        'SELECT AVG(amount) as average FROM transactions WHERE type = 1';
    List<dynamic> args = [];

    if (start != null && end != null) {
      query += ' AND date BETWEEN ? AND ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['average'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> getMonthlyTotals(int year) async {
    final db = await _db.database;
    final Map<String, double> monthlyTotals = {};

    for (int month = 1; month <= 12; month++) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);

      final result = await db.rawQuery(
        '''
        SELECT 
          COALESCE(SUM(CASE WHEN type = 0 THEN amount ELSE 0 END), 0) as income,
          COALESCE(SUM(CASE WHEN type = 1 THEN amount ELSE 0 END), 0) as expense
        FROM transactions
        WHERE date BETWEEN ? AND ?
      ''',
        [start.toIso8601String(), end.toIso8601String()],
      );

      final income = (result.first['income'] as num?)?.toDouble() ?? 0;
      final expense = (result.first['expense'] as num?)?.toDouble() ?? 0;
      monthlyTotals['${month}_income'] = income;
      monthlyTotals['${month}_expense'] = expense;
    }

    return monthlyTotals;
  }
}
