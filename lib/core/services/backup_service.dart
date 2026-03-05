import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../services/storage_service.dart';

class BackupService {
  static const int _supportedBackupVersion = 1;
  static const int _maxRecordsPerCollection = 50000;

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
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        throw const FormatException('Backup root must be an object');
      }
      final backupData = Map<String, dynamic>.from(decoded);

      return await restoreFromBackup(backupData);
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }

  Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    final parsedBackup = _validateBackupDataOrThrow(backupData);
    final db = await _db.database;

    return await db.transaction((txn) async {
      try {
        if (parsedBackup.settings != null) {
          final settings = parsedBackup.settings!;
          final storage = await StorageService.getInstance();

          if (settings['currencyCode'] != null) {
            await storage.setCurrencyCode(settings['currencyCode'] as String);
          }
          if (settings['currencySymbol'] != null) {
            await storage.setCurrencySymbol(settings['currencySymbol'] as String);
          }
          if (settings['locale'] != null) {
            await storage.setLocale(settings['locale'] as String);
          }
          if (settings['themeMode'] != null) {
            await storage.setThemeMode(settings['themeMode'] as int);
          }
        }

        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('accounts');
        await txn.delete('budgets');

        for (final map in parsedBackup.categories) {
          await txn.insert('categories', map);
        }

        for (final map in parsedBackup.accounts) {
          await txn.insert('accounts', map);
        }

        for (final map in parsedBackup.transactions) {
          await txn.insert('transactions', map);
        }

        for (final map in parsedBackup.budgets) {
          await txn.insert('budgets', map);
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
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        throw const FormatException('Backup root must be an object');
      }
      final backupData = Map<String, dynamic>.from(decoded);
      final parsedBackup = _validateBackupDataOrThrow(backupData);

      return BackupValidationResult(
        isValid: true,
        version: parsedBackup.version,
        createdAt: parsedBackup.createdAt,
        transactionCount: parsedBackup.transactions.length,
        categoryCount: parsedBackup.categories.length,
        accountCount: parsedBackup.accounts.length,
        budgetCount: parsedBackup.budgets.length,
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

  _ParsedBackup _validateBackupDataOrThrow(Map<String, dynamic> backupData) {
    final version = backupData['version'];
    if (version is! int) {
      throw const FormatException('Invalid backup version');
    }
    if (version > _supportedBackupVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    DateTime? createdAt;
    final createdAtRaw = backupData['createdAt'];
    if (createdAtRaw != null) {
      if (createdAtRaw is! String) {
        throw const FormatException('createdAt must be a string');
      }
      createdAt = _parseIsoDateTime(createdAtRaw, 'createdAt');
    }

    final settings = _normalizeSettings(backupData['settings']);
    final categories = _normalizeCategoryRecords(
      _readRecordList(backupData, 'categories'),
    );
    final accounts = _normalizeAccountRecords(
      _readRecordList(backupData, 'accounts'),
    );
    final categoryIds = categories.map((c) => c['id'] as String).toSet();
    final accountIds = accounts.map((a) => a['id'] as String).toSet();

    final transactions = _normalizeTransactionRecords(
      _readRecordList(backupData, 'transactions'),
      categoryIds: categoryIds,
      accountIds: accountIds,
    );

    final budgets = _normalizeBudgetRecords(
      _readRecordList(backupData, 'budgets'),
      categoryIds: categoryIds,
    );

    return _ParsedBackup(
      version: version,
      createdAt: createdAt,
      settings: settings,
      transactions: transactions,
      categories: categories,
      accounts: accounts,
      budgets: budgets,
    );
  }

  Map<String, dynamic>? _normalizeSettings(dynamic rawSettings) {
    if (rawSettings == null) return null;
    if (rawSettings is! Map) {
      throw const FormatException('settings must be an object');
    }

    final settings = Map<String, dynamic>.from(rawSettings);
    final normalized = <String, dynamic>{};

    if (settings['currencyCode'] != null) {
      normalized['currencyCode'] = _asString(
        settings['currencyCode'],
        'settings.currencyCode',
        maxLength: 8,
      );
    }
    if (settings['currencySymbol'] != null) {
      normalized['currencySymbol'] = _asString(
        settings['currencySymbol'],
        'settings.currencySymbol',
        maxLength: 8,
      );
    }
    if (settings['locale'] != null) {
      normalized['locale'] = _asString(
        settings['locale'],
        'settings.locale',
        maxLength: 32,
      );
    }
    if (settings['themeMode'] != null) {
      final mode = _normalizeThemeMode(settings['themeMode']);
      normalized['themeMode'] = mode;
    }

    return normalized;
  }

  List<Map<String, dynamic>> _readRecordList(
    Map<String, dynamic> backupData,
    String fieldName,
  ) {
    final rawList = backupData[fieldName];
    if (rawList == null) return [];
    if (rawList is! List) {
      throw FormatException('$fieldName must be a list');
    }
    if (rawList.length > _maxRecordsPerCollection) {
      throw FormatException('$fieldName exceeds max allowed records');
    }

    final records = <Map<String, dynamic>>[];
    for (var i = 0; i < rawList.length; i++) {
      final rawRecord = rawList[i];
      if (rawRecord is! Map) {
        throw FormatException('$fieldName[$i] must be an object');
      }
      records.add(Map<String, dynamic>.from(rawRecord));
    }

    return records;
  }

  List<Map<String, dynamic>> _normalizeCategoryRecords(
    List<Map<String, dynamic>> records,
  ) {
    final normalized = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final id = _asString(record['id'], 'categories[$i].id', maxLength: 64);
      if (!seenIds.add(id)) {
        throw FormatException('Duplicate category id: $id');
      }

      normalized.add({
        'id': id,
        'name': _asString(record['name'], 'categories[$i].name', maxLength: 120),
        'iconCodePoint': _asInt(
          record['iconCodePoint'],
          'categories[$i].iconCodePoint',
          min: 0,
        ),
        'iconFontFamily': record['iconFontFamily'] == null
            ? null
            : _asString(
                record['iconFontFamily'],
                'categories[$i].iconFontFamily',
                maxLength: 64,
              ),
        'color': _asInt(record['color'], 'categories[$i].color'),
        'isIncome': _asBoolFlag(record['isIncome'], 'categories[$i].isIncome'),
        'isDefault': _asBoolFlag(
          record['isDefault'] ?? 0,
          'categories[$i].isDefault',
        ),
        'sortOrder': _asInt(record['sortOrder'] ?? 0, 'categories[$i].sortOrder'),
        'createdAt': _parseIsoDateTime(
          _asString(record['createdAt'], 'categories[$i].createdAt'),
          'categories[$i].createdAt',
        ).toIso8601String(),
      });
    }

    return normalized;
  }

  List<Map<String, dynamic>> _normalizeAccountRecords(
    List<Map<String, dynamic>> records,
  ) {
    final normalized = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final id = _asString(record['id'], 'accounts[$i].id', maxLength: 64);
      if (!seenIds.add(id)) {
        throw FormatException('Duplicate account id: $id');
      }

      normalized.add({
        'id': id,
        'name': _asString(record['name'], 'accounts[$i].name', maxLength: 120),
        'type': _asInt(
          record['type'],
          'accounts[$i].type',
          min: 0,
          max: AccountType.values.length - 1,
        ),
        'balance': _asDouble(record['balance'], 'accounts[$i].balance'),
        'initialBalance': _asDouble(
          record['initialBalance'],
          'accounts[$i].initialBalance',
        ),
        'iconCodePoint': _asInt(
          record['iconCodePoint'],
          'accounts[$i].iconCodePoint',
          min: 0,
        ),
        'iconFontFamily': record['iconFontFamily'] == null
            ? null
            : _asString(
                record['iconFontFamily'],
                'accounts[$i].iconFontFamily',
                maxLength: 64,
              ),
        'color': _asInt(record['color'], 'accounts[$i].color'),
        'currency': _asString(
          record['currency'],
          'accounts[$i].currency',
          maxLength: 8,
        ),
        'includeInTotal': _asBoolFlag(
          record['includeInTotal'] ?? 1,
          'accounts[$i].includeInTotal',
        ),
        'isDefault': _asBoolFlag(
          record['isDefault'] ?? 0,
          'accounts[$i].isDefault',
        ),
        'createdAt': _parseIsoDateTime(
          _asString(record['createdAt'], 'accounts[$i].createdAt'),
          'accounts[$i].createdAt',
        ).toIso8601String(),
        'updatedAt': _parseIsoDateTime(
          _asString(record['updatedAt'], 'accounts[$i].updatedAt'),
          'accounts[$i].updatedAt',
        ).toIso8601String(),
      });
    }

    return normalized;
  }

  List<Map<String, dynamic>> _normalizeTransactionRecords(
    List<Map<String, dynamic>> records, {
    required Set<String> categoryIds,
    required Set<String> accountIds,
  }) {
    final normalized = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final id = _asString(record['id'], 'transactions[$i].id', maxLength: 64);
      if (!seenIds.add(id)) {
        throw FormatException('Duplicate transaction id: $id');
      }

      final type = _asInt(
        record['type'],
        'transactions[$i].type',
        min: 0,
        max: TransactionType.values.length - 1,
      );
      final categoryId = _asString(
        record['categoryId'],
        'transactions[$i].categoryId',
        maxLength: 64,
      );
      if (!categoryIds.contains(categoryId)) {
        throw FormatException(
          'transactions[$i].categoryId references unknown category',
        );
      }

      final accountId = _asString(
        record['accountId'],
        'transactions[$i].accountId',
        maxLength: 64,
      );
      if (!accountIds.contains(accountId)) {
        throw FormatException(
          'transactions[$i].accountId references unknown account',
        );
      }

      String? toAccountId;
      if (record['toAccountId'] != null) {
        toAccountId = _asString(
          record['toAccountId'],
          'transactions[$i].toAccountId',
          maxLength: 64,
        );
        if (!accountIds.contains(toAccountId)) {
          throw FormatException(
            'transactions[$i].toAccountId references unknown account',
          );
        }
      }

      if (type == TransactionType.transfer.index) {
        if (toAccountId == null) {
          throw FormatException(
            'transactions[$i].toAccountId is required for transfer',
          );
        }
        if (toAccountId == accountId) {
          throw FormatException(
            'transactions[$i] transfer account cannot equal destination account',
          );
        }
      } else {
        toAccountId = null;
      }

      normalized.add({
        'id': id,
        'title': _asString(record['title'], 'transactions[$i].title', maxLength: 200),
        'amount': _asDouble(record['amount'], 'transactions[$i].amount', min: 0),
        'type': type,
        'categoryId': categoryId,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'date': _parseIsoDateTime(
          _asString(record['date'], 'transactions[$i].date'),
          'transactions[$i].date',
        ).toIso8601String(),
        'note': record['note'] == null
            ? null
            : _asString(record['note'], 'transactions[$i].note', maxLength: 2000),
        'receiptImage': record['receiptImage'] == null
            ? null
            : _asString(
                record['receiptImage'],
                'transactions[$i].receiptImage',
                maxLength: 4096,
              ),
        'isRecurring': _asBoolFlag(
          record['isRecurring'] ?? 0,
          'transactions[$i].isRecurring',
        ),
        'recurringId': record['recurringId'] == null
            ? null
            : _asString(
                record['recurringId'],
                'transactions[$i].recurringId',
                maxLength: 64,
              ),
        'createdAt': _parseIsoDateTime(
          _asString(record['createdAt'], 'transactions[$i].createdAt'),
          'transactions[$i].createdAt',
        ).toIso8601String(),
        'updatedAt': _parseIsoDateTime(
          _asString(record['updatedAt'], 'transactions[$i].updatedAt'),
          'transactions[$i].updatedAt',
        ).toIso8601String(),
      });
    }

    return normalized;
  }

  List<Map<String, dynamic>> _normalizeBudgetRecords(
    List<Map<String, dynamic>> records, {
    required Set<String> categoryIds,
  }) {
    final normalized = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final id = _asString(record['id'], 'budgets[$i].id', maxLength: 64);
      if (!seenIds.add(id)) {
        throw FormatException('Duplicate budget id: $id');
      }

      final categoryId = _asString(
        record['categoryId'],
        'budgets[$i].categoryId',
        maxLength: 64,
      );
      if (!categoryIds.contains(categoryId)) {
        throw FormatException('budgets[$i].categoryId references unknown category');
      }

      normalized.add({
        'id': id,
        'name': _asString(record['name'], 'budgets[$i].name', maxLength: 120),
        'amount': _asDouble(record['amount'], 'budgets[$i].amount', min: 0),
        'spent': _asDouble(record['spent'] ?? 0, 'budgets[$i].spent', min: 0),
        'categoryId': categoryId,
        'period': _asInt(
          record['period'],
          'budgets[$i].period',
          min: 0,
          max: BudgetPeriod.values.length - 1,
        ),
        'startDate': _parseIsoDateTime(
          _asString(record['startDate'], 'budgets[$i].startDate'),
          'budgets[$i].startDate',
        ).toIso8601String(),
        'endDate': _parseIsoDateTime(
          _asString(record['endDate'], 'budgets[$i].endDate'),
          'budgets[$i].endDate',
        ).toIso8601String(),
        'isActive': _asBoolFlag(record['isActive'] ?? 1, 'budgets[$i].isActive'),
        'notifyOnExceed': _asBoolFlag(
          record['notifyOnExceed'] ?? 1,
          'budgets[$i].notifyOnExceed',
        ),
        'notifyAtPercent': _asInt(
          record['notifyAtPercent'] ?? 80,
          'budgets[$i].notifyAtPercent',
          min: 1,
          max: 100,
        ),
        'createdAt': _parseIsoDateTime(
          _asString(record['createdAt'], 'budgets[$i].createdAt'),
          'budgets[$i].createdAt',
        ).toIso8601String(),
        'updatedAt': _parseIsoDateTime(
          _asString(record['updatedAt'], 'budgets[$i].updatedAt'),
          'budgets[$i].updatedAt',
        ).toIso8601String(),
      });
    }

    return normalized;
  }

  String _asString(
    dynamic value,
    String fieldName, {
    int maxLength = 1024,
  }) {
    if (value is! String) {
      throw FormatException('$fieldName must be a string');
    }
    if (value.isEmpty) {
      throw FormatException('$fieldName must not be empty');
    }
    if (value.length > maxLength) {
      throw FormatException('$fieldName is too long');
    }
    return value;
  }

  int _asInt(dynamic value, String fieldName, {int? min, int? max}) {
    int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is double && value == value.roundToDouble()) {
      intValue = value.toInt();
    } else {
      throw FormatException('$fieldName must be an integer');
    }

    if (min != null && intValue < min) {
      throw FormatException('$fieldName is below minimum');
    }
    if (max != null && intValue > max) {
      throw FormatException('$fieldName is above maximum');
    }
    return intValue;
  }

  double _asDouble(dynamic value, String fieldName, {double? min}) {
    if (value is! num) {
      throw FormatException('$fieldName must be a number');
    }
    final doubleValue = value.toDouble();
    if (doubleValue.isNaN || doubleValue.isInfinite) {
      throw FormatException('$fieldName must be a finite number');
    }
    if (min != null && doubleValue < min) {
      throw FormatException('$fieldName is below minimum');
    }
    return doubleValue;
  }

  int _asBoolFlag(dynamic value, String fieldName) {
    if (value is bool) return value ? 1 : 0;
    if (value is int && (value == 0 || value == 1)) return value;
    throw FormatException('$fieldName must be a boolean flag');
  }

  DateTime _parseIsoDateTime(String value, String fieldName) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$fieldName must be a valid ISO datetime');
    }
    return parsed;
  }

  int _normalizeThemeMode(dynamic value) {
    if (value is int) {
      if (value < 0 || value > 2) {
        throw FormatException('settings.themeMode is invalid: $value');
      }
      return value;
    }

    if (value is String) {
      const modeMap = {'system': 0, 'light': 1, 'dark': 2};
      final normalized = modeMap[value.toLowerCase()];
      if (normalized != null) {
        return normalized;
      }
    }

    throw const FormatException('settings.themeMode is invalid');
  }
}

class _ParsedBackup {
  final int version;
  final DateTime? createdAt;
  final Map<String, dynamic>? settings;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> budgets;

  _ParsedBackup({
    required this.version,
    required this.createdAt,
    required this.settings,
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.budgets,
  });
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
