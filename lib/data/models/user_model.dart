import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? avatar;
  final String currency;
  final String currencySymbol;
  final String locale;
  final ThemeMode themeMode;
  final String? pinHash;
  final bool biometricEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.avatar,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.locale = 'en_US',
    this.themeMode = ThemeMode.system,
    this.pinHash,
    this.biometricEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'locale': locale,
      'themeMode': themeMode.index,
      'pinHash': pinHash,
      'biometricEnabled': biometricEnabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatar: map['avatar'],
      currency: map['currency'] ?? 'USD',
      currencySymbol: map['currencySymbol'] ?? '\$',
      locale: map['locale'] ?? 'en_US',
      themeMode: ThemeMode.values[map['themeMode'] ?? 0],
      pinHash: map['pinHash'],
      biometricEnabled: map['biometricEnabled'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? currency,
    String? currencySymbol,
    String? locale,
    ThemeMode? themeMode,
    String? pinHash,
    bool? biometricEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      pinHash: pinHash ?? this.pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  String get displayName => name ?? email ?? 'User';

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
