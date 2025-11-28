class BudgetModel {
  final String id;
  final String name;
  final double amount;
  final double spent;
  final String categoryId;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool notifyOnExceed;
  final int notifyAtPercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.name,
    required this.amount,
    this.spent = 0,
    required this.categoryId,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.notifyOnExceed = true,
    this.notifyAtPercent = 80,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get remaining => amount - spent;
  double get percentUsed => (spent / amount * 100).clamp(0, 100);
  bool get isExceeded => spent > amount;
  bool get isNearLimit => percentUsed >= notifyAtPercent;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'spent': spent,
      'categoryId': categoryId,
      'period': period.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'notifyOnExceed': notifyOnExceed ? 1 : 0,
      'notifyAtPercent': notifyAtPercent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      spent: map['spent'] ?? 0,
      categoryId: map['categoryId'],
      period: BudgetPeriod.values[map['period']],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'] == 1,
      notifyOnExceed: map['notifyOnExceed'] == 1,
      notifyAtPercent: map['notifyAtPercent'] ?? 80,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? name,
    double? amount,
    double? spent,
    String? categoryId,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? notifyOnExceed,
    int? notifyAtPercent,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notifyOnExceed: notifyOnExceed ?? this.notifyOnExceed,
      notifyAtPercent: notifyAtPercent ?? this.notifyAtPercent,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

enum BudgetPeriod { daily, weekly, monthly, yearly, custom }
