import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/dialogs/icon_picker_dialog.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? category;
  final bool isIncome;

  const AddCategoryScreen({super.key, this.category, this.isIncome = false});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  IconData _selectedIcon = Icons.category;
  Color _selectedColor = AppColors.categoryColors[0];
  bool _isLoading = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
        actions: [
          if (_isEditing && !widget.category!.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCategory,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      border: Border.all(color: _selectedColor, width: 3),
                    ),
                    child: Icon(_selectedIcon, size: 50, color: _selectedColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isIncome
                          ? AppColors.income.withValues(alpha: 0.1)
                          : AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      widget.isIncome ? 'Income Category' : 'Expense Category',
                      style: TextStyle(
                        color: widget.isIncome
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            CustomTextField(
              controller: _nameController,
              label: 'Category Name',
              hint: 'e.g., Food, Transport, Salary',
              prefixIcon: Icons.label_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter category name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.lg),

            const Text('Icon', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSizes.sm),
            InkWell(
              onTap: _showIconPicker,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(_selectedIcon, color: _selectedColor),
                    ),
                    const SizedBox(width: AppSizes.md),
                    const Expanded(
                      child: Text(
                        'Tap to change icon',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            const Text('Color', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: AppColors.categoryColors.map((color) {
                final isSelected =
                    _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 4)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.xl),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveCategory,
              style: ElevatedButton.styleFrom(backgroundColor: _selectedColor),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Update Category' : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => IconPickerDialog(
        selectedIcon: _selectedIcon,
        color: _selectedColor,
        onSelect: (icon) {
          setState(() => _selectedIcon = icon);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final category = CategoryModel(
      id: widget.category?.id ?? '',
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      isIncome: widget.isIncome,
      isDefault: widget.category?.isDefault ?? false,
      sortOrder: widget.category?.sortOrder ?? 0,
    );

    final provider = context.read<CategoryProvider>();
    final success = _isEditing
        ? await provider.updateCategory(category)
        : await provider.addCategory(category);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Category updated' : 'Category added'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
          'Are you sure you want to delete this category? Transactions using this category will be moved to "Other".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        final success = await context.read<CategoryProvider>().deleteCategory(
          widget.category!.id,
        );
        if (success && mounted) {
          await Future.wait([
            context.read<TransactionProvider>().loadTransactions(),
            context.read<BudgetProvider>().loadBudgets(),
          ]);
          if (!mounted) return;
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to delete category'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
