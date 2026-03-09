import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';

enum BiometricPreferenceResult {
  enabled,
  disabled,
  unavailable,
  authenticationFailed,
}

class SettingsProvider with ChangeNotifier {
  StorageService? _storage;
  bool _isInitialized = false;
  final _notificationService = NotificationService();
  final _localAuth = LocalAuthentication();

  bool _notificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _dailyReminderEnabled = false;
  String _dailyReminderTime = '20:00';
  bool _biometricEnabled = false;
  bool _showBalance = true;
  String? _pinHash;
  String? _pinSalt;
  int _pinFailedAttempts = 0;
  DateTime? _pinLockoutUntil;
  DateTime? _lastUnlockVerifiedAt;
  static const int _pinAttemptsBeforeLockout = 5;
  static const Duration _unlockGracePeriod = Duration(seconds: 3);

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
  bool get shouldSuppressImmediateRelock =>
      _lastUnlockVerifiedAt != null &&
      DateTime.now().difference(_lastUnlockVerifiedAt!) < _unlockGracePeriod;
  int get pinFailedAttempts => _pinFailedAttempts;
  bool get isPinLockedOut =>
      _pinLockoutUntil != null && DateTime.now().isBefore(_pinLockoutUntil!);
  int get pinAttemptsRemaining {
    if (isPinLockedOut) return 0;
    final usedAttempts = _pinFailedAttempts % _pinAttemptsBeforeLockout;
    return _pinAttemptsBeforeLockout - usedAttempts;
  }
  int get pinLockoutSecondsRemaining {
    if (!isPinLockedOut) return 0;
    return _pinLockoutUntil!.difference(DateTime.now()).inSeconds.clamp(0, 9999);
  }
  DateTime? get pinLockoutUntil => _pinLockoutUntil;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _storage = await StorageService.getInstance();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SettingsProvider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    if (_storage == null) return;

    _notificationsEnabled = _storage!.notificationsEnabled;
    _budgetAlertsEnabled = _storage!.budgetAlertsEnabled;
    _dailyReminderEnabled = _storage!.dailyReminderEnabled;
    _dailyReminderTime = _storage!.dailyReminderTime ?? '20:00';
    _biometricEnabled = _storage!.biometricEnabled;
    _showBalance = _storage!.showBalance;
    _pinHash = _storage!.pinHash;
    _pinSalt = _storage!.pinSalt;
    _pinFailedAttempts = _storage!.pinFailedAttempts;
    _pinLockoutUntil = _storage!.pinLockoutUntil;
    _autoBackupEnabled = _storage!.getBool('auto_backup_enabled') ?? false;
    _autoBackupRetention = _storage!.getInt('auto_backup_retention') ?? 5;

    if (_pinLockoutUntil != null && !isPinLockedOut) {
      await _storage!.setPinLockoutUntil(null);
      _pinLockoutUntil = null;
    }

    await _syncDailyReminderSchedule();

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
    await _syncDailyReminderSchedule();
    notifyListeners();
  }

  Future<void> setDailyReminderTime(String value) async {
    _dailyReminderTime = value;
    await _storage?.setDailyReminderTime(value);
    await _syncDailyReminderSchedule();
    notifyListeners();
  }

  Future<BiometricPreferenceResult> setBiometricEnabled(bool value) async {
    if (value) {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) {
        _biometricEnabled = false;
        await _storage?.setBiometricEnabled(false);
        notifyListeners();
        return BiometricPreferenceResult.unavailable;
      }

      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock',
          biometricOnly: false,
          sensitiveTransaction: false,
          persistAcrossBackgrounding: false,
        );

        if (!didAuthenticate) {
          return BiometricPreferenceResult.authenticationFailed;
        }
      } catch (e) {
        debugPrint('Error enabling biometric lock: $e');
        return BiometricPreferenceResult.authenticationFailed;
      }
    }

    _biometricEnabled = value;
    await _storage?.setBiometricEnabled(value);
    if (value) {
      markUnlockVerified();
    }
    debugPrint(
      'Biometric enabled set to: $value, Lock enabled: $isLockEnabled',
    );
    notifyListeners();
    return value
        ? BiometricPreferenceResult.enabled
        : BiometricPreferenceResult.disabled;
  }

  Future<void> setShowBalance(bool value) async {
    _showBalance = value;
    await _storage?.setShowBalance(value);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    _pinSalt = salt;
    _pinHash = _hashPin(pin, salt);
    await _storage?.setPinHash(_pinHash);
    await _storage?.setPinSalt(_pinSalt);
    await _storage?.setPinFailedAttempts(0);
    _pinFailedAttempts = 0;
    await clearPinLockout();
    debugPrint('PIN set, Lock enabled: $isLockEnabled');
    notifyListeners();
  }

  Future<void> removePin() async {
    _pinHash = null;
    _pinSalt = null;
    await _storage?.setPinHash(null);
    await _storage?.setPinSalt(null);
    await _storage?.setPinFailedAttempts(0);
    _pinFailedAttempts = 0;
    await clearPinLockout();
    debugPrint('PIN removed, Lock enabled: $isLockEnabled');
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (_pinHash == null || _pinHash!.isEmpty) return false;

    final isValid = (_pinSalt == null || _pinSalt!.isEmpty)
        ? _constantTimeEquals(_pinHash!, _legacyHashPin(pin))
        : _constantTimeEquals(_pinHash!, _hashPin(pin, _pinSalt!));

    debugPrint('PIN verification: $isValid');
    return isValid;
  }

  Future<void> setPinLockout(Duration duration) async {
    _pinLockoutUntil = DateTime.now().add(duration);
    await _storage?.setPinLockoutUntil(_pinLockoutUntil);
    notifyListeners();
  }

  Future<void> clearPinLockout() async {
    _pinLockoutUntil = null;
    await _storage?.setPinLockoutUntil(null);
  }

  Future<void> recordFailedPinAttempt() async {
    _pinFailedAttempts += 1;
    await _storage?.setPinFailedAttempts(_pinFailedAttempts);

    if (_pinFailedAttempts % _pinAttemptsBeforeLockout == 0) {
      await setPinLockout(_lockoutDurationForAttempts(_pinFailedAttempts));
      return;
    }

    notifyListeners();
  }

  Future<void> recordSuccessfulPinEntry() async {
    _pinFailedAttempts = 0;
    await _storage?.setPinFailedAttempts(0);
    await clearPinLockout();
    markUnlockVerified();
    notifyListeners();
  }

  void markUnlockVerified() {
    _lastUnlockVerifiedAt = DateTime.now();
  }

  Future<void> refreshPinLockout({bool notify = true}) async {
    if (_storage == null) return;
    _pinLockoutUntil = _storage!.pinLockoutUntil;
    _pinFailedAttempts = _storage!.pinFailedAttempts;
    if (_pinLockoutUntil != null && !isPinLockedOut) {
      await clearPinLockout();
    }
    if (notify) {
      notifyListeners();
    }
  }

  Duration _lockoutDurationForAttempts(int failedAttempts) {
    final strikeLevel = (failedAttempts / _pinAttemptsBeforeLockout).floor();

    if (strikeLevel <= 1) return const Duration(seconds: 30);
    if (strikeLevel == 2) return const Duration(minutes: 2);
    if (strikeLevel == 3) return const Duration(minutes: 5);
    return const Duration(minutes: 15);
  }

  String _legacyHashPin(String pin) {
    int hash = 0;
    for (int i = 0; i < pin.length; i++) {
      hash = 31 * hash + pin.codeUnitAt(i);
    }
    return hash.toString();
  }

  String _hashPin(String pin, String salt) {
    final seed = utf8.encode('$salt:$pin');
    var digest = sha256.convert(seed).bytes;

    // Slow hash to make offline brute force materially harder.
    for (int i = 0; i < 12000; i++) {
      digest = sha256.convert([...digest, ...seed]).bytes;
    }

    return base64Encode(digest);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  Future<void> _syncDailyReminderSchedule() async {
    if (!_dailyReminderEnabled) {
      await _notificationService.cancelNotification(0);
      return;
    }

    final parts = _dailyReminderTime.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    await _notificationService.scheduleDailyReminder(hour: hour, minute: minute);
  }

  Future<void> reload() async {
    await _loadSettings();
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
