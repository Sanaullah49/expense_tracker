import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database/database_helper.dart';
import '../data/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => !c.isIncome).toList();
  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      _categories = await _db.getAllCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }

    _isLoading = false;
    if (_categories.isNotEmpty) {
      Future.microtask(() => notifyListeners());
    }
  }

  Future<bool> addCategory(CategoryModel category) async {
    try {
      final newCategory = CategoryModel(
        id: _uuid.v4(),
        name: category.name,
        icon: category.icon,
        color: category.color,
        isIncome: category.isIncome,
        sortOrder: _categories.length,
      );

      await _db.insertCategory(newCategory);
      _categories.add(newCategory);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _db.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _db.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  String getCategoryName(String id) {
    return getCategoryById(id)?.name ?? 'Unknown';
  }
}
