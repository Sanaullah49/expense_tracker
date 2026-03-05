import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  static const String keyFirstTime = 'is_first_time';
  static const String keyThemeMode = 'theme_mode';
  static const String keyCurrencyCode = 'currency_code';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyLocale = 'locale';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserAvatar = 'user_avatar';
  static const String keyUserCreatedAt = 'user_created_at';
  static const String keyPinHash = 'pin_hash';
  static const String keyPinSalt = 'pin_salt';
  static const String keyPinFailedAttempts = 'pin_failed_attempts';
  static const String keyPinLockoutUntil = 'pin_lockout_until';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBudgetAlertsEnabled = 'budget_alerts_enabled';
  static const String keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String keyDailyReminderTime = 'daily_reminder_time';
  static const String keyLastBackupDate = 'last_backup_date';
  static const String keyLastSyncDate = 'last_sync_date';
  static const String keyDefaultAccountId = 'default_account_id';
  static const String keyShowBalance = 'show_balance';
  static const String keyRecentCategories = 'recent_categories';
  static const String keyAppOpenCount = 'app_open_count';
  static const String keyHasRated = 'has_rated';

  Future<bool> setString(String key, String value) async {
    return await _preferences!.setString(key, value);
  }

  String? getString(String key) {
    return _preferences!.getString(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _preferences!.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    return await _preferences!.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _preferences!.getDouble(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _preferences!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences!.getBool(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences!.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _preferences!.getStringList(key);
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await _preferences!.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final value = _preferences!.getString(key);
    if (value != null) {
      return jsonDecode(value) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> remove(String key) async {
    return await _preferences!.remove(key);
  }

  Future<bool> clear() async {
    return await _preferences!.clear();
  }

  bool containsKey(String key) {
    return _preferences!.containsKey(key);
  }

  bool get isFirstTime => getBool(keyFirstTime) ?? true;
  Future<void> setFirstTime(bool value) => setBool(keyFirstTime, value);

  int get themeMode => getInt(keyThemeMode) ?? 0;
  Future<void> setThemeMode(int value) => setInt(keyThemeMode, value);

  String get currencyCode => getString(keyCurrencyCode) ?? 'USD';
  Future<void> setCurrencyCode(String value) =>
      setString(keyCurrencyCode, value);

  String get currencySymbol => getString(keyCurrencySymbol) ?? '\$';
  Future<void> setCurrencySymbol(String value) =>
      setString(keyCurrencySymbol, value);

  String get locale => getString(keyLocale) ?? 'en_US';
  Future<void> setLocale(String value) => setString(keyLocale, value);

  String? get userId => getString(keyUserId);
  Future<void> setUserId(String value) => setString(keyUserId, value);

  String? get userName => getString(keyUserName);
  Future<void> setUserName(String value) => setString(keyUserName, value);

  String? get userEmail => getString(keyUserEmail);
  Future<void> setUserEmail(String value) => setString(keyUserEmail, value);

  String? get userAvatar => getString(keyUserAvatar);
  Future<void> setUserAvatar(String? value) async {
    if (value != null && value.isNotEmpty) {
      await setString(keyUserAvatar, value);
    } else {
      await remove(keyUserAvatar);
    }
  }

  DateTime? get userCreatedAt {
    final value = getString(keyUserCreatedAt);
    return value != null ? DateTime.parse(value) : null;
  }

  Future<void> setUserCreatedAt(DateTime value) =>
      setString(keyUserCreatedAt, value.toIso8601String());

  String? get pinHash => getString(keyPinHash);
  Future<void> setPinHash(String? value) async {
    if (value != null) {
      await setString(keyPinHash, value);
    } else {
      await remove(keyPinHash);
    }
  }

  String? get pinSalt => getString(keyPinSalt);
  Future<void> setPinSalt(String? value) async {
    if (value != null && value.isNotEmpty) {
      await setString(keyPinSalt, value);
    } else {
      await remove(keyPinSalt);
    }
  }

  int get pinFailedAttempts => getInt(keyPinFailedAttempts) ?? 0;
  Future<void> setPinFailedAttempts(int value) =>
      setInt(keyPinFailedAttempts, value);

  DateTime? get pinLockoutUntil {
    final value = getString(keyPinLockoutUntil);
    return value != null ? DateTime.tryParse(value) : null;
  }

  Future<void> setPinLockoutUntil(DateTime? value) async {
    if (value == null) {
      await remove(keyPinLockoutUntil);
      return;
    }
    await setString(keyPinLockoutUntil, value.toIso8601String());
  }

  bool get biometricEnabled => getBool(keyBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool value) =>
      setBool(keyBiometricEnabled, value);

  bool get notificationsEnabled => getBool(keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      setBool(keyNotificationsEnabled, value);

  bool get budgetAlertsEnabled => getBool(keyBudgetAlertsEnabled) ?? true;
  Future<void> setBudgetAlertsEnabled(bool value) =>
      setBool(keyBudgetAlertsEnabled, value);

  bool get dailyReminderEnabled => getBool(keyDailyReminderEnabled) ?? false;
  Future<void> setDailyReminderEnabled(bool value) =>
      setBool(keyDailyReminderEnabled, value);

  String? get dailyReminderTime => getString(keyDailyReminderTime);
  Future<void> setDailyReminderTime(String value) =>
      setString(keyDailyReminderTime, value);

  DateTime? get lastBackupDate {
    final value = getString(keyLastBackupDate);
    return value != null ? DateTime.parse(value) : null;
  }

  Future<void> setLastBackupDate(DateTime value) =>
      setString(keyLastBackupDate, value.toIso8601String());

  String? get defaultAccountId => getString(keyDefaultAccountId);
  Future<void> setDefaultAccountId(String value) =>
      setString(keyDefaultAccountId, value);

  bool get showBalance => getBool(keyShowBalance) ?? true;
  Future<void> setShowBalance(bool value) => setBool(keyShowBalance, value);

  List<String> get recentCategories => getStringList(keyRecentCategories) ?? [];
  Future<void> setRecentCategories(List<String> value) =>
      setStringList(keyRecentCategories, value);

  Future<void> addRecentCategory(String categoryId) async {
    final recent = recentCategories;
    recent.remove(categoryId);
    recent.insert(0, categoryId);
    if (recent.length > 5) {
      recent.removeLast();
    }
    await setRecentCategories(recent);
  }

  int get appOpenCount => getInt(keyAppOpenCount) ?? 0;
  Future<void> incrementAppOpenCount() async {
    await setInt(keyAppOpenCount, appOpenCount + 1);
  }

  bool get hasRated => getBool(keyHasRated) ?? false;
  Future<void> setHasRated(bool value) => setBool(keyHasRated, value);
}
