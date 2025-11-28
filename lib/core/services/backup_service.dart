import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../services/storage_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> createBackupData() async {
    try {
      final transactions = await _db.getAllTransactions();
      final categories = await _db.getAllCategories();
      final accounts = await _db.getAllAccounts();
      final budgets = await _db.getAllBudgets();

      final storage = await StorageService.getInstance();

      return {
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {
          'currencyCode': storage.currencyCode,
          'currencySymbol': storage.currencySymbol,
          'locale': storage.locale,
          'themeMode': storage.themeMode,
        },
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
      };
    } catch (e) {
      debugPrint('Error creating backup data: $e');
      rethrow;
    }
  }

  Future<File> exportBackup() async {
    try {
      final backupData = await createBackupData();
      final jsonString = jsonEncode(backupData);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(
        '${directory.path}/expense_tracker_backup_$timestamp.json',
      );

      await file.writeAsString(jsonString);

      final storage = await StorageService.getInstance();
      await storage.setLastBackupDate(DateTime.now());

      return file;
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      rethrow;
    }
  }

  Future<void> shareBackup() async {
    try {
      final file = await exportBackup();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Expense Tracker Backup',
          text: 'My Expense Tracker data backup',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing backup: $e');
      rethrow;
    }
  }

  Future<bool> importBackup(File file) async {
    try {
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      return await restoreFromBackup(backupData);
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }

  Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      try {
        final version = backupData['version'] as int?;
        if (version == null) throw Exception('Invalid backup format');

        if (backupData['settings'] != null) {
          final settings = backupData['settings'] as Map<String, dynamic>;
          final storage = await StorageService.getInstance();

          if (settings['currencyCode'] != null) {
            await storage.setCurrencyCode(settings['currencyCode']);
          }
          if (settings['currencySymbol'] != null) {
            await storage.setCurrencySymbol(settings['currencySymbol']);
          }
          if (settings['locale'] != null) {
            await storage.setLocale(settings['locale']);
          }
          if (settings['themeMode'] != null) {
            await storage.setThemeMode(settings['themeMode']);
          }
        }

        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('accounts');
        await txn.delete('budgets');

        if (backupData['categories'] != null) {
          for (var map in (backupData['categories'] as List)) {
            await txn.insert('categories', CategoryModel.fromMap(map).toMap());
          }
        }

        if (backupData['accounts'] != null) {
          for (var map in (backupData['accounts'] as List)) {
            await txn.insert('accounts', AccountModel.fromMap(map).toMap());
          }
        }

        if (backupData['transactions'] != null) {
          for (var map in (backupData['transactions'] as List)) {
            await txn.insert(
              'transactions',
              TransactionModel.fromMap(map).toMap(),
            );
          }
        }

        if (backupData['budgets'] != null) {
          for (var map in (backupData['budgets'] as List)) {
            await txn.insert('budgets', BudgetModel.fromMap(map).toMap());
          }
        }

        return true;
      } catch (e) {
        debugPrint('Error restoring backup (rolled back): $e');
        rethrow;
      }
    });
  }

  Future<int> getBackupSize() async {
    try {
      final backupData = await createBackupData();
      final jsonString = jsonEncode(backupData);
      return utf8.encode(jsonString).length;
    } catch (e) {
      return 0;
    }
  }

  Future<BackupValidationResult> validateBackup(File file) async {
    try {
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      final version = backupData['version'] as int?;
      final createdAt = backupData['createdAt'] as String?;
      final transactions = backupData['transactions'] as List?;
      final categories = backupData['categories'] as List?;
      final accounts = backupData['accounts'] as List?;
      final budgets = backupData['budgets'] as List?;

      if (version == null) {
        return BackupValidationResult(
          isValid: false,
          error: 'Invalid backup format: missing version',
        );
      }

      return BackupValidationResult(
        isValid: true,
        version: version,
        createdAt: createdAt != null ? DateTime.parse(createdAt) : null,
        transactionCount: transactions?.length ?? 0,
        categoryCount: categories?.length ?? 0,
        accountCount: accounts?.length ?? 0,
        budgetCount: budgets?.length ?? 0,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        error: 'Error reading backup file: $e',
      );
    }
  }

  Future<void> autoBackup(int retentionCount) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final files = await backupDir.list().toList();
      files.sort((a, b) => b.path.compareTo(a.path));

      if (files.length >= retentionCount) {
        for (var i = retentionCount - 1; i < files.length; i++) {
          await files[i].delete();
        }
      }

      final backupData = await createBackupData();
      final jsonString = jsonEncode(backupData);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${backupDir.path}/auto_backup_$timestamp.json');

      await file.writeAsString(jsonString);

      final storage = await StorageService.getInstance();
      await storage.setLastBackupDate(DateTime.now());

      debugPrint('Auto backup complete: ${file.path}');
    } catch (e) {
      debugPrint('Error in auto backup: $e');
    }
  }

  Future<List<BackupInfo>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final backups = <BackupInfo>[];

      for (var file in files) {
        final stat = await file.stat();
        final validation = await validateBackup(File(file.path));

        backups.add(
          BackupInfo(
            path: file.path,
            size: stat.size,
            modifiedAt: stat.modified,
            validation: validation,
          ),
        );
      }

      backups.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return backups;
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }

  Future<bool> deleteBackup(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      return false;
    }
  }

  Future<bool> deleteAllBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting all backups: $e');
      return false;
    }
  }

  Future<void> performAutoBackupIfNeeded(bool isEnabled, int retention) async {
    if (!isEnabled) return;

    final storage = await StorageService.getInstance();
    final lastBackup = storage.lastBackupDate;
    final now = DateTime.now();

    if (lastBackup == null || now.difference(lastBackup).inHours >= 24) {
      debugPrint('Performing auto backup...');
      await autoBackup(retention);
    }
  }
}

class BackupValidationResult {
  final bool isValid;
  final String? error;
  final int? version;
  final DateTime? createdAt;
  final int transactionCount;
  final int categoryCount;
  final int accountCount;
  final int budgetCount;

  BackupValidationResult({
    required this.isValid,
    this.error,
    this.version,
    this.createdAt,
    this.transactionCount = 0,
    this.categoryCount = 0,
    this.accountCount = 0,
    this.budgetCount = 0,
  });

  int get totalItems =>
      transactionCount + categoryCount + accountCount + budgetCount;
}

class BackupInfo {
  final String path;
  final int size;
  final DateTime modifiedAt;
  final BackupValidationResult validation;

  BackupInfo({
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.validation,
  });

  String get fileName => path.split('/').last;

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
