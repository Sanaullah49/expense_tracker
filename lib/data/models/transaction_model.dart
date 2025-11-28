enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String? toAccountId;
  final DateTime date;
  final String? note;
  final String? receiptImage;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.receiptImage,
    this.isRecurring = false,
    this.recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'date': date.toIso8601String(),
      'note': note,
      'receiptImage': receiptImage,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringId': recurringId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      toAccountId: map['toAccountId'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      receiptImage: map['receiptImage'],
      isRecurring: map['isRecurring'] == 1,
      recurringId: map['recurringId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? note,
    String? receiptImage,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptImage: receiptImage ?? this.receiptImage,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
