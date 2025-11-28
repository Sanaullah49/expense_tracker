import 'package:flutter/foundation.dart';

import '../core/services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  StorageService? _storage;
  bool _isInitialized = false;

  bool _notificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _dailyReminderEnabled = false;
  String _dailyReminderTime = '20:00';
  bool _biometricEnabled = false;
  bool _showBalance = true;
  String? _pinHash;

  bool _autoBackupEnabled = false;
  int _autoBackupRetention = 5;

  bool get autoBackupEnabled => _autoBackupEnabled;
  int get autoBackupRetention => _autoBackupRetention;

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get budgetAlertsEnabled => _budgetAlertsEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  String get dailyReminderTime => _dailyReminderTime;
  bool get biometricEnabled => _biometricEnabled;
  bool get showBalance => _showBalance;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;
  bool get isLockEnabled => hasPin || _biometricEnabled;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _storage = await StorageService.getInstance();
      _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SettingsProvider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _loadSettings() {
    if (_storage == null) return;

    _notificationsEnabled = _storage!.notificationsEnabled;
    _budgetAlertsEnabled = _storage!.budgetAlertsEnabled;
    _dailyReminderEnabled = _storage!.dailyReminderEnabled;
    _dailyReminderTime = _storage!.dailyReminderTime ?? '20:00';
    _biometricEnabled = _storage!.biometricEnabled;
    _showBalance = _storage!.showBalance;
    _pinHash = _storage!.pinHash;
    _autoBackupEnabled = _storage!.getBool('auto_backup_enabled') ?? false;
    _autoBackupRetention = _storage!.getInt('auto_backup_retention') ?? 5;
    debugPrint(
      'Settings loaded - PIN hash exists: $hasPin, Biometric: $_biometricEnabled, Lock enabled: $isLockEnabled',
    );
  }

  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    int attempts = 0;
    while (!_isInitialized && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _storage?.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setBudgetAlertsEnabled(bool value) async {
    _budgetAlertsEnabled = value;
    await _storage?.setBudgetAlertsEnabled(value);
    notifyListeners();
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    _dailyReminderEnabled = value;
    await _storage?.setDailyReminderEnabled(value);
    notifyListeners();
  }

  Future<void> setDailyReminderTime(String value) async {
    _dailyReminderTime = value;
    await _storage?.setDailyReminderTime(value);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await _storage?.setBiometricEnabled(value);
    debugPrint(
      'Biometric enabled set to: $value, Lock enabled: $isLockEnabled',
    );
    notifyListeners();
  }

  Future<void> setShowBalance(bool value) async {
    _showBalance = value;
    await _storage?.setShowBalance(value);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _pinHash = _hashPin(pin);
    await _storage?.setPinHash(_pinHash);
    debugPrint('PIN set, Lock enabled: $isLockEnabled');
    notifyListeners();
  }

  Future<void> removePin() async {
    _pinHash = null;
    await _storage?.setPinHash(null);
    debugPrint('PIN removed, Lock enabled: $isLockEnabled');
    notifyListeners();
  }

  bool verifyPin(String pin) {
    final inputHash = _hashPin(pin);
    final isValid = _pinHash == inputHash;
    debugPrint('PIN verification: $isValid');
    return isValid;
  }

  String _hashPin(String pin) {
    int hash = 0;
    for (int i = 0; i < pin.length; i++) {
      hash = 31 * hash + pin.codeUnitAt(i);
    }
    return hash.toString();
  }

  Future<void> reload() async {
    _loadSettings();
    notifyListeners();
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    _autoBackupEnabled = value;
    await _storage?.setBool('auto_backup_enabled', value);
    notifyListeners();
  }

  Future<void> setAutoBackupRetention(int value) async {
    _autoBackupRetention = value;
    await _storage?.setInt('auto_backup_retention', value);
    notifyListeners();
  }
}
