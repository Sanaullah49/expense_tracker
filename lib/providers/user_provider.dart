import 'package:flutter/foundation.dart';

import '../core/services/storage_service.dart';
import '../data/models/user_model.dart';

class UserProvider with ChangeNotifier {
  late StorageService _storage;
  UserModel? _user;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  String get displayName => _user?.displayName ?? 'User';
  String get initials => _user?.initials ?? 'U';

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    _storage = await StorageService.getInstance();
    await _loadUser();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final userId = _storage.userId;
    if (userId != null) {
      _user = UserModel(
        id: userId,
        name: _storage.userName,
        email: _storage.userEmail,
        currency: _storage.currencyCode,
        currencySymbol: _storage.currencySymbol,
        locale: _storage.locale,
      );
    }
  }

  Future<void> updateUser({String? name, String? email, String? avatar}) async {
    if (_user == null) {
      _user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        avatar: avatar,
      );
      await _storage.setUserId(_user!.id);
    } else {
      _user = _user!.copyWith(name: name, email: email, avatar: avatar);
    }

    if (name != null) await _storage.setUserName(name);
    if (email != null) await _storage.setUserEmail(email);

    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    await _storage.remove(StorageService.keyUserId);
    await _storage.remove(StorageService.keyUserName);
    await _storage.remove(StorageService.keyUserEmail);
    notifyListeners();
  }
}
