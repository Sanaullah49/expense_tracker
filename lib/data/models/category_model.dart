import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
    this.isDefault = false,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'color': color.toARGB32(),
      'isIncome': isIncome ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      color: Color(map['color']),
      isIncome: map['isIncome'] == 1,
      isDefault: map['isDefault'] == 1,
      sortOrder: map['sortOrder'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isIncome,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncome: isIncome ?? this.isIncome,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}

class DefaultCategories {
  static List<CategoryModel> get expenseCategories => [
    CategoryModel(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: const Color(0xFFE74C3C),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transportation',
      icon: Icons.directions_car,
      color: const Color(0xFF3498DB),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: const Color(0xFF9B59B6),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'bills',
      name: 'Bills & Utilities',
      icon: Icons.receipt_long,
      color: const Color(0xFFF39C12),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: const Color(0xFFE91E63),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health & Fitness',
      icon: Icons.favorite,
      color: const Color(0xFF00BCD4),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: const Color(0xFF673AB7),
      isIncome: false,
      isDefault: true,
    ),
    CategoryModel(
      id: 'other_expense',
      name: 'Other',
      icon: Icons.more_horiz,
      color: const Color(0xFF95A5A6),
      isIncome: false,
      isDefault: true,
    ),
  ];

  static List<CategoryModel> get incomeCategories => [
    CategoryModel(
      id: 'salary',
      name: 'Salary',
      icon: Icons.work,
      color: const Color(0xFF27AE60),
      isIncome: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'freelance',
      name: 'Freelance',
      icon: Icons.laptop_mac,
      color: const Color(0xFF2ECC71),
      isIncome: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'investment',
      name: 'Investments',
      icon: Icons.trending_up,
      color: const Color(0xFF1ABC9C),
      isIncome: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'gift',
      name: 'Gifts',
      icon: Icons.card_giftcard,
      color: const Color(0xFFE74C3C),
      isIncome: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'other_income',
      name: 'Other',
      icon: Icons.more_horiz,
      color: const Color(0xFF95A5A6),
      isIncome: true,
      isDefault: true,
    ),
  ];
}
