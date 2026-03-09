import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/dialogs/category_picker_dialog.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  CategoryModel? _selectedCategory;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _notifyOnExceed = true;
  int _notifyAtPercent = 80;
  bool _isLoading = false;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final b = widget.budget!;
    _nameController.text = b.name;
    _amountController.text = b.amount.toString();
    _selectedPeriod = b.period;
    _startDate = b.startDate;
    _endDate = b.endDate;
    _notifyOnExceed = b.notifyOnExceed;
    _notifyAtPercent = b.notifyAtPercent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = context.read<CategoryProvider>().categories;
      setState(() {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == b.categoryId,
          orElse: () => categories.first,
        );
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Budget' : 'Create Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Budget Name',
              hint: 'e.g., Monthly Food Budget',
              prefixIcon: Icons.label_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),

            CustomTextField(
              controller: _amountController,
              label: 'Budget Amount',
              hint: '0.00',
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),

            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSizes.sm),
            InkWell(
              onTap: _showCategoryPicker,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            _selectedCategory?.color.withValues(alpha: 0.2) ??
                            scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        _selectedCategory?.icon ?? Icons.category,
                        color:
                            _selectedCategory?.color ??
                            scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        _selectedCategory?.name ?? 'Select Category',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            const Text(
              'Budget Period',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: BudgetPeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return ChoiceChip(
                  label: Text(_getPeriodLabel(period)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod = period;
                      _updateDates();
                    });
                  },
                  showCheckmark: true,
                  checkmarkColor: AppColors.primary,
                  selectedColor: AppColors.primary.withValues(alpha: 0.14),
                  backgroundColor: scheme.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : theme.dividerColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 10,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : scheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.md),

            if (_selectedPeriod == BudgetPeriod.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: _buildDateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
            ],

            const Divider(),
            const SizedBox(height: AppSizes.sm),
            SwitchListTile(
              title: const Text('Notify when exceeded'),
              subtitle: const Text('Get notified when you exceed your budget'),
              value: _notifyOnExceed,
              onChanged: (value) => setState(() => _notifyOnExceed = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Alert Threshold',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _notifyAtPercent.toDouble(),
              min: 50,
              max: 100,
              divisions: 10,
              label: '$_notifyAtPercent%',
              onChanged: (value) {
                setState(() => _notifyAtPercent = value.toInt());
              },
            ),
            Text(
              'Alert me when I reach $_notifyAtPercent% of my budget',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveBudget,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Update Budget' : 'Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Daily';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.custom:
        return 'Custom';
    }
  }

  void _updateDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case BudgetPeriod.daily:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 1));
        break;
      case BudgetPeriod.weekly:
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case BudgetPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case BudgetPeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case BudgetPeriod.custom:
        break;
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryPickerDialog(
        isIncome: false,
        selectedCategory: _selectedCategory,
        onSelect: (category) {
          setState(() => _selectedCategory = category);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    final budget = BudgetModel(
      id: widget.budget?.id ?? '',
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      spent: widget.budget?.spent ?? 0,
      categoryId: _selectedCategory!.id,
      period: _selectedPeriod,
      startDate: _startDate,
      endDate: _endDate,
      notifyOnExceed: _notifyOnExceed,
      notifyAtPercent: _notifyAtPercent,
    );

    final provider = context.read<BudgetProvider>();
    final success = _isEditing
        ? await provider.updateBudget(budget)
        : await provider.addBudget(budget);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Budget updated' : 'Budget created'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
