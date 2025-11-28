import '../database/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> insert(CategoryModel category) async {
    return await _db.insertCategory(category);
  }

  Future<void> insertAll(List<CategoryModel> categories) async {
    for (var category in categories) {
      await _db.insertCategory(category);
    }
  }

  Future<List<CategoryModel>> getAll() async {
    return await _db.getAllCategories();
  }

  Future<CategoryModel?> getById(String id) async {
    final categories = await _db.getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<CategoryModel>> getByType(bool isIncome) async {
    return await _db.getCategoriesByType(isIncome);
  }

  Future<List<CategoryModel>> getExpenseCategories() async {
    return await _db.getCategoriesByType(false);
  }

  Future<List<CategoryModel>> getIncomeCategories() async {
    return await _db.getCategoriesByType(true);
  }

  Future<List<CategoryModel>> getDefaultCategories() async {
    final db = await _db.database;
    final result = await db.query(
      'categories',
      where: 'isDefault = ?',
      whereArgs: [1],
      orderBy: 'sortOrder ASC',
    );
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<List<CategoryModel>> getCustomCategories() async {
    final db = await _db.database;
    final result = await db.query(
      'categories',
      where: 'isDefault = ?',
      whereArgs: [0],
      orderBy: 'sortOrder ASC',
    );
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> update(CategoryModel category) async {
    return await _db.updateCategory(category);
  }

  Future<void> updateSortOrder(List<CategoryModel> categories) async {
    final db = await _db.database;
    for (int i = 0; i < categories.length; i++) {
      await db.update(
        'categories',
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [categories[i].id],
      );
    }
  }

  Future<int> delete(String id) async {
    return await _db.deleteCategory(id);
  }

  Future<int> deleteCustomCategories() async {
    final db = await _db.database;
    return await db.delete(
      'categories',
      where: 'isDefault = ?',
      whereArgs: [0],
    );
  }

  Future<int> deleteAll() async {
    final db = await _db.database;
    return await db.delete('categories');
  }

  Future<bool> isInUse(String id) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE categoryId = ?',
      [id],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<int> getUsageCount(String id) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE categoryId = ?',
      [id],
    );
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getMostUsedCategories({
    int limit = 5,
  }) async {
    final db = await _db.database;
    return await db.rawQuery(
      '''
      SELECT categoryId, COUNT(*) as count
      FROM transactions
      GROUP BY categoryId
      ORDER BY count DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<void> resetToDefaults() async {
    await deleteAll();
    final allCategories = [
      ...DefaultCategories.expenseCategories,
      ...DefaultCategories.incomeCategories,
    ];
    await insertAll(allCategories);
  }
}
