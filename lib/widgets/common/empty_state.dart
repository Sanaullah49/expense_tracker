import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final String? lottieAsset;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.lottieAsset,
    this.actionLabel,
    this.onAction,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (lottieAsset != null)
                        Lottie.asset(
                          lottieAsset!,
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _buildDefaultIcon(),
                        )
                      else
                        _buildDefaultIcon(),
                      const SizedBox(height: 24),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: onAction,
                          icon: const Icon(Icons.add),
                          label: Text(actionLabel!),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.inbox_outlined,
        size: iconSize / 1.5,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

class EmptyTransactions extends StatelessWidget {
  final VoidCallback? onAdd;

  const EmptyTransactions({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No transactions yet',
      description:
          'Start tracking your expenses by adding your first transaction',
      icon: Icons.receipt_long_outlined,
      actionLabel: 'Add Transaction',
      onAction: onAdd,
    );
  }
}

class EmptyAccounts extends StatelessWidget {
  final VoidCallback? onAdd;

  const EmptyAccounts({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No accounts yet',
      description:
          'Add your bank accounts, wallets, or credit cards to track your money',
      icon: Icons.account_balance_wallet_outlined,
      actionLabel: 'Add Account',
      onAction: onAdd,
    );
  }
}

class EmptyBudgets extends StatelessWidget {
  final VoidCallback? onAdd;

  const EmptyBudgets({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No budgets yet',
      description: 'Create a budget to manage your spending and save more',
      icon: Icons.pie_chart_outline,
      actionLabel: 'Create Budget',
      onAction: onAdd,
    );
  }
}

class EmptyCategories extends StatelessWidget {
  final VoidCallback? onAdd;

  const EmptyCategories({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No categories yet',
      description: 'Add custom categories to organize your transactions',
      icon: Icons.category_outlined,
      actionLabel: 'Add Category',
      onAction: onAdd,
    );
  }
}

class EmptySearchResults extends StatelessWidget {
  final String query;
  final VoidCallback? onClear;

  const EmptySearchResults({super.key, required this.query, this.onClear});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No results found',
      description:
          'No transactions match "$query".\nTry a different search term.',
      icon: Icons.search_off,
      actionLabel: onClear != null ? 'Clear Search' : null,
      onAction: onClear,
    );
  }
}

class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
