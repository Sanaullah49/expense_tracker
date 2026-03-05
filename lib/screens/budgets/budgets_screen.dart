import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import 'add_budget_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = provider.budgets;

          if (budgets.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadBudgets(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                AppSizes.md,
                AppSizes.md,
                100,
              ),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: BudgetCard(budget: budgets[index]),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          right: AppSizes.sm,
          bottom: AppSizes.md,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Budget'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a budget to track your spending',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final BudgetModel budget;

  const BudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final category = categoryProvider.getCategoryById(budget.categoryId);

    final progressColor = budget.isExceeded
        ? AppColors.error
        : budget.isNearLimit
        ? AppColors.warning
        : AppColors.success;

    return Card(
      child: InkWell(
        onTap: () => _showBudgetDetails(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (category?.color ?? Colors.grey).withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      category?.icon ?? Icons.category,
                      color: category?.color ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          category?.name ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (budget.isExceeded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Text(
                        'Exceeded',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: LinearProgressIndicator(
                  value: budget.percentUsed / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currencyProvider.formatAmount(budget.spent)} spent',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    '${currencyProvider.formatAmount(budget.remaining)} left',
                    style: TextStyle(
                      color: budget.remaining < 0
                          ? AppColors.error
                          : Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${budget.percentUsed.toStringAsFixed(0)}% used',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'of ${currencyProvider.formatAmount(budget.amount)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetDetailsSheet(budget: budget),
    );
  }
}

class BudgetDetailsSheet extends StatelessWidget {
  final BudgetModel budget;

  const BudgetDetailsSheet({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final category = categoryProvider.getCategoryById(budget.categoryId);

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (category?.color ?? Colors.grey).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  category?.icon ?? Icons.category,
                  color: category?.color ?? Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getPeriodLabel(budget.period),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddBudgetScreen(budget: budget),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  'Budget Amount',
                  currencyProvider.formatAmount(budget.amount),
                ),
                const Divider(),
                _buildStatRow(
                  'Spent',
                  currencyProvider.formatAmount(budget.spent),
                  valueColor: AppColors.expense,
                ),
                const Divider(),
                _buildStatRow(
                  'Remaining',
                  currencyProvider.formatAmount(budget.remaining),
                  valueColor: budget.remaining < 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteBudget(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final txProvider = context.read<TransactionProvider>();

                    txProvider.clearFilters();

                    txProvider.setType(TransactionType.expense);
                    txProvider.setCategory(budget.categoryId);
                    txProvider.setDateRange(budget.startDate, budget.endDate);

                    Navigator.pop(context);

                    Navigator.pushNamed(context, AppRoutes.transactions).then((
                      _,
                    ) {
                      if (context.mounted) {
                        txProvider.clearFilters();
                      }
                    });
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Transactions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Daily Budget';
      case BudgetPeriod.weekly:
        return 'Weekly Budget';
      case BudgetPeriod.monthly:
        return 'Monthly Budget';
      case BudgetPeriod.yearly:
        return 'Yearly Budget';
      case BudgetPeriod.custom:
        return 'Custom Period';
    }
  }

  void _deleteBudget(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
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

    if (confirm == true && context.mounted) {
      await context.read<BudgetProvider>().deleteBudget(budget.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
