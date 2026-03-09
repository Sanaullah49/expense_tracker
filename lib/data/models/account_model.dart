import 'package:flutter/material.dart';

import '../../core/constants/icon_catalog.dart';

enum AccountType { cash, bank, creditCard, savings, investment, other }

class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final double initialBalance;
  final IconData icon;
  final Color color;
  final String currency;
  final bool includeInTotal;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.initialBalance,
    required this.icon,
    required this.color,
    required this.currency,
    this.includeInTotal = true,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'initialBalance': initialBalance,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'color': color.toARGB32(),
      'currency': currency,
      'includeInTotal': includeInTotal ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    final typeIndex = (map['type'] as num).toInt();
    final type = AccountType.values[typeIndex];
    return AccountModel(
      id: map['id'],
      name: map['name'],
      type: type,
      balance: (map['balance'] as num).toDouble(),
      initialBalance: (map['initialBalance'] as num).toDouble(),
      icon: AppIconCatalog.fromCodePoint(
        map['iconCodePoint'],
        fallback: _defaultIconForType(type),
      ),
      color: Color(map['color']),
      currency: map['currency'],
      includeInTotal: map['includeInTotal'] == 1,
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    double? initialBalance,
    IconData? icon,
    Color? color,
    String? currency,
    bool? includeInTotal,
    bool? isDefault,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      currency: currency ?? this.currency,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get typeLabel {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.savings:
        return 'Savings';
      case AccountType.investment:
        return 'Investment';
      case AccountType.other:
        return 'Other';
    }
  }

  static IconData _defaultIconForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.account_balance_wallet;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.more_horiz;
    }
  }
}
