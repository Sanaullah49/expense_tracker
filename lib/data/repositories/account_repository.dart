import '../database/database_helper.dart';
import '../models/account_model.dart';

class AccountRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(AccountModel account) async {
    return await _db.insertAccount(account);
  }

  Future<List<AccountModel>> getAll() async {
    return await _db.getAllAccounts();
  }

  Future<AccountModel?> getById(String id) async {
    final accounts = await _db.getAllAccounts();
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<AccountModel?> getDefault() async {
    final db = await _db.database;
    final result = await db.query(
      'accounts',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return AccountModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<AccountModel>> getByType(AccountType type) async {
    final db = await _db.database;
    final result = await db.query(
      'accounts',
      where: 'type = ?',
      whereArgs: [type.index],
    );
    return result.map((map) => AccountModel.fromMap(map)).toList();
  }

  Future<List<AccountModel>> getIncludedInTotal() async {
    final db = await _db.database;
    final result = await db.query(
      'accounts',
      where: 'includeInTotal = ?',
      whereArgs: [1],
    );
    return result.map((map) => AccountModel.fromMap(map)).toList();
  }

  Future<double> getTotalBalance() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total 
      FROM accounts 
      WHERE includeInTotal = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalBalanceByType(AccountType type) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(balance), 0) as total 
      FROM accounts 
      WHERE type = ?
    ''',
      [type.index],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> update(AccountModel account) async {
    return await _db.updateAccount(account);
  }

  Future<int> updateBalance(String id, double newBalance) async {
    return await _db.updateAccountBalance(id, newBalance);
  }

  Future<void> setDefault(String id) async {
    final db = await _db.database;

    await db.update(
      'accounts',
      {'isDefault': 0},
      where: 'isDefault = ?',
      whereArgs: [1],
    );

    await db.update(
      'accounts',
      {'isDefault': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> adjustBalance(String id, double amount) async {
    final account = await getById(id);
    if (account != null) {
      final newBalance = account.balance + amount;
      await updateBalance(id, newBalance);
    }
  }

  Future<int> delete(String id) async {
    return await _db.deleteAccount(id);
  }

  Future<int> deleteAll() async {
    final db = await _db.database;
    return await db.delete('accounts');
  }

  Future<bool> isInUse(String id) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM transactions 
      WHERE accountId = ? OR toAccountId = ?
    ''',
      [id, id],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<int> getTransactionCount(String id) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM transactions 
      WHERE accountId = ? OR toAccountId = ?
    ''',
      [id, id],
    );
    return result.first['count'] as int;
  }

  Future<Map<String, double>> getAccountStats(
    String id, {
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _db.database;

    String dateFilter = '';
    List<dynamic> args = [id, id];

    if (start != null && end != null) {
      dateFilter = ' AND date BETWEEN ? AND ?';
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 0 AND accountId = ? THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN type = 1 AND accountId = ? THEN amount ELSE 0 END), 0) as expense,
        COALESCE(SUM(CASE WHEN type = 2 AND accountId = ? THEN amount ELSE 0 END), 0) as transferOut,
        COALESCE(SUM(CASE WHEN type = 2 AND toAccountId = ? THEN amount ELSE 0 END), 0) as transferIn
      FROM transactions
      WHERE (accountId = ? OR toAccountId = ?)$dateFilter
    ''',
      [id, id, id, id, ...args],
    );

    return {
      'income': (result.first['income'] as num?)?.toDouble() ?? 0,
      'expense': (result.first['expense'] as num?)?.toDouble() ?? 0,
      'transferOut': (result.first['transferOut'] as num?)?.toDouble() ?? 0,
      'transferIn': (result.first['transferIn'] as num?)?.toDouble() ?? 0,
    };
  }
}
