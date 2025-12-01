import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';

class CategoryPickerDialog extends StatelessWidget {
  final bool isIncome;
  final CategoryModel? selectedCategory;
  final Function(CategoryModel) onSelect;

  const CategoryPickerDialog({
    super.key,
    required this.isIncome,
    this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIncome ? 'Income Category' : 'Expense Category',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a category',
                      style: TextStyle(fontSize: 13, color: theme.hintColor),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addCategory,
                      arguments: {'isIncome': isIncome},
                    );
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'New Category',
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: AppSizes.lg, endIndent: AppSizes.lg),

          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, provider, _) {
                final categories = isIncome
                    ? provider.incomeCategories
                    : provider.expenseCategories;

                if (categories.isEmpty) {
                  return _buildEmptyState(context);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSizes.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory?.id == category.id;

                    return _CategoryCardItem(
                      category: category,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelect(category);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.addCategory,
                arguments: {'isIncome': isIncome},
              );
            },
            child: const Text('Create First Category'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCardItem extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCardItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? category.color.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF2D2D44) : Colors.white),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isSelected
              ? category.color
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: category.color, size: 18),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? category.color
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),

                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle, size: 16, color: category.color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
