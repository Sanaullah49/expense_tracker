import '../../data/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class RecurringService {
  static final RecurringService _instance = RecurringService._();
  factory RecurringService() => _instance;
  RecurringService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> checkAndGenerateRecurringTransactions() async {
    final transactions = await _db.getAllTransactions();
    final recurring = transactions.where((t) => t.isRecurring).toList();
    final now = DateTime.now();

    for (var t in recurring) {
      final nextDate = DateTime(t.date.year, t.date.month + 1, t.date.day);

      if (now.isAfter(nextDate)) {
        final hasGenerated = transactions.any(
          (child) =>
              child.recurringId == t.id &&
              child.date.month == now.month &&
              child.date.year == now.year,
        );

        if (!hasGenerated) {
          final newTrans = t.copyWith(
            id: const Uuid().v4(),
            date: DateTime(now.year, now.month, t.date.day),
            recurringId: t.id,
            isRecurring: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _db.insertTransaction(newTrans);
        }
      }
    }
  }
}
