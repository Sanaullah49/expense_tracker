import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        categoryId TEXT NOT NULL,
        accountId TEXT NOT NULL,
        toAccountId TEXT,
        date TEXT NOT NULL,
        note TEXT,
        receiptImage TEXT,
        isRecurring INTEGER DEFAULT 0,
        recurringId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT,
        color INTEGER NOT NULL,
        isIncome INTEGER NOT NULL,
        isDefault INTEGER DEFAULT 0,
        sortOrder INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance REAL NOT NULL,
        initialBalance REAL NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT,
        color INTEGER NOT NULL,
        currency TEXT NOT NULL,
        includeInTotal INTEGER DEFAULT 1,
        isDefault INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        spent REAL DEFAULT 0,
        categoryId TEXT NOT NULL,
        period INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        notifyOnExceed INTEGER DEFAULT 1,
        notifyAtPercent INTEGER DEFAULT 80,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(categoryId)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_account ON transactions(accountId)',
    );

    await _insertDefaultCategories(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // In v2, we might add a 'budget_limit' column to categories
      // await db.execute("ALTER TABLE categories ADD COLUMN budget_limit REAL DEFAULT 0");
    }

    if (oldVersion < 3) {
      // In v3, we might add a new table
      // await db.execute("CREATE TABLE ... ");
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final allCategories = [
      ...DefaultCategories.expenseCategories,
      ...DefaultCategories.incomeCategories,
    ];

    for (var category in allCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByCategory(
    String categoryId,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'sortOrder ASC');
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(bool isIncome) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'isIncome = ?',
      whereArgs: [isIncome ? 1 : 0],
      orderBy: 'sortOrder ASC',
    );
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertAccount(AccountModel account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts');
    return result.map((map) => AccountModel.fromMap(map)).toList();
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> updateAccountBalance(String id, double newBalance) async {
    final db = await database;
    return await db.update(
      'accounts',
      {'balance': newBalance, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAccount(String id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBudget(BudgetModel budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets');
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<List<BudgetModel>> getActiveBudgets() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'budgets',
      where: 'isActive = 1 AND endDate >= ?',
      whereArgs: [now],
    );
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> updateBudgetSpent(String id, double spent) async {
    final db = await database;
    return await db.update(
      'budgets',
      {'spent': spent, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getTotalsByType(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

    final incomeResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM transactions 
      WHERE type = 0 AND date BETWEEN ? AND ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    final expenseResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM transactions 
      WHERE type = 1 AND date BETWEEN ? AND ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return {
      'income': (incomeResult.first['total'] as num?)?.toDouble() ?? 0,
      'expense': (expenseResult.first['total'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT categoryId, SUM(amount) as total
      FROM transactions
      WHERE type = 1 AND date BETWEEN ? AND ?
      GROUP BY categoryId
      ORDER BY total DESC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT DATE(date) as day, type, SUM(amount) as total
      FROM transactions
      WHERE date BETWEEN ? AND ?
      GROUP BY DATE(date), type
      ORDER BY day ASC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
