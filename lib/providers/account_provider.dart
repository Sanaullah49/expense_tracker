import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_colors.dart';
import '../data/database/database_helper.dart';
import '../data/models/account_model.dart';
import '../data/models/transaction_model.dart';

class AccountProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String? _error;

  List<AccountModel> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBalance => _accounts
      .where((a) => a.includeInTotal)
      .fold(0, (sum, a) => sum + a.balance);

  double get totalIncome => _accounts
      .where((a) => a.includeInTotal && a.balance > 0)
      .fold(0, (sum, a) => sum + a.balance);

  int get accountCount => _accounts.length;

  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _db.getAllAccounts();

      if (_accounts.isEmpty) {
        await _createDefaultAccount();
      }
    } catch (e) {
      _error = 'Failed to load accounts: $e';
      debugPrint('Error loading accounts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _createDefaultAccount() async {
    final defaultAccount = AccountModel(
      id: _uuid.v4(),
      name: 'Cash',
      type: AccountType.cash,
      balance: 0,
      initialBalance: 0,
      icon: Icons.account_balance_wallet,
      color: AppColors.primary,
      currency: 'USD',
      isDefault: true,
    );

    await _db.insertAccount(defaultAccount);
    _accounts.add(defaultAccount);
  }

  Future<bool> addAccount(AccountModel account) async {
    try {
      final shouldBeDefault = _accounts.isEmpty || account.isDefault;

      if (shouldBeDefault && _accounts.isNotEmpty) {
        await _clearDefaultStatus();
      }

      final newAccount = AccountModel(
        id: _uuid.v4(),
        name: account.name,
        type: account.type,
        balance: account.initialBalance,
        initialBalance: account.initialBalance,
        icon: account.icon,
        color: account.color,
        currency: account.currency,
        includeInTotal: account.includeInTotal,
        isDefault: shouldBeDefault,
      );

      await _db.insertAccount(newAccount);
      _accounts.add(newAccount);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding account: $e');
      return false;
    }
  }

  Future<bool> updateAccount(AccountModel account) async {
    try {
      await _db.updateAccount(account);
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating account: $e');
      return false;
    }
  }

  Future<bool> updateBalance(String id, double amount) async {
    try {
      final index = _accounts.indexWhere((a) => a.id == id);
      if (index != -1) {
        final newBalance = _accounts[index].balance + amount;
        await _db.updateAccountBalance(id, newBalance);
        _accounts[index] = _accounts[index].copyWith(balance: newBalance);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating balance: $e');
      return false;
    }
  }

  Future<bool> setBalance(String id, double newBalance) async {
    try {
      final index = _accounts.indexWhere((a) => a.id == id);
      if (index != -1) {
        await _db.updateAccountBalance(id, newBalance);
        _accounts[index] = _accounts[index].copyWith(balance: newBalance);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error setting balance: $e');
      return false;
    }
  }

  Future<bool> transferBetweenAccounts(
    String fromAccountId,
    String toAccountId,
    double amount,
  ) async {
    try {
      final fromIndex = _accounts.indexWhere((a) => a.id == fromAccountId);
      final toIndex = _accounts.indexWhere((a) => a.id == toAccountId);

      if (fromIndex == -1 || toIndex == -1) {
        debugPrint('Account not found for transfer');
        return false;
      }

      final fromNewBalance = _accounts[fromIndex].balance - amount;
      final toNewBalance = _accounts[toIndex].balance + amount;

      await _db.updateAccountBalance(fromAccountId, fromNewBalance);
      await _db.updateAccountBalance(toAccountId, toNewBalance);

      _accounts[fromIndex] = _accounts[fromIndex].copyWith(
        balance: fromNewBalance,
      );
      _accounts[toIndex] = _accounts[toIndex].copyWith(balance: toNewBalance);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error transferring between accounts: $e');
      return false;
    }
  }

  Future<bool> setDefault(String id) async {
    try {
      await _clearDefaultStatus();

      final index = _accounts.indexWhere((a) => a.id == id);
      if (index != -1) {
        final updatedAccount = _accounts[index].copyWith(isDefault: true);
        await _db.updateAccount(updatedAccount);
        _accounts[index] = updatedAccount;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting default account: $e');
      return false;
    }
  }

  Future<void> _clearDefaultStatus() async {
    for (int i = 0; i < _accounts.length; i++) {
      if (_accounts[i].isDefault) {
        final updated = _accounts[i].copyWith(isDefault: false);
        await _db.updateAccount(updated);
        _accounts[i] = updated;
      }
    }
  }

  Future<bool> deleteAccount(String id) async {
    try {
      final account = getAccountById(id);
      if (account == null) return false;

      if (_accounts.length <= 1) {
        debugPrint('Cannot delete the last account');
        return false;
      }

      final wasDefault = account.isDefault;
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete(
          'transactions',
          where: 'accountId = ? OR toAccountId = ?',
          whereArgs: [id, id],
        );
        await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
      });
      _accounts.removeWhere((a) => a.id == id);

      if (wasDefault && _accounts.isNotEmpty) {
        await setDefault(_accounts.first.id);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  Future<void> recalculateAllBalances() async {
    try {
      final db = await _db.database;
      final txRows = await db.query('transactions');
      final transactions = txRows.map((row) => TransactionModel.fromMap(row)).toList();

      bool hasUpdates = false;
      for (int i = 0; i < _accounts.length; i++) {
        final account = _accounts[i];
        double calculated = account.initialBalance;

        for (final tx in transactions) {
          switch (tx.type) {
            case TransactionType.income:
              if (tx.accountId == account.id) {
                calculated += tx.amount;
              }
              break;
            case TransactionType.expense:
              if (tx.accountId == account.id) {
                calculated -= tx.amount;
              }
              break;
            case TransactionType.transfer:
              if (tx.accountId == account.id) {
                calculated -= tx.amount;
              }
              if (tx.toAccountId == account.id) {
                calculated += tx.amount;
              }
              break;
          }
        }

        if (account.balance != calculated) {
          await _db.updateAccountBalance(account.id, calculated);
          _accounts[i] = account.copyWith(balance: calculated);
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error recalculating account balances: $e');
      await loadAccounts();
    }
  }

  AccountModel? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  String getAccountName(String id) {
    return getAccountById(id)?.name ?? 'Unknown';
  }

  AccountModel? get defaultAccount {
    try {
      return _accounts.firstWhere((a) => a.isDefault);
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }

  List<AccountModel> getAccountsByType(AccountType type) {
    return _accounts.where((a) => a.type == type).toList();
  }

  double getBalanceChange(String accountId, DateTime from, DateTime to) {
    return 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
