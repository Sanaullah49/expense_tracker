import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.transaction, this.onTap});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final time = DateFormat('h:mm a').format(date);

    if (dateOnly == today) {
      return 'Today, $time';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, $time';
    } else {
      return '${DateFormat('MMM d').format(date)} • $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final category = categoryProvider.getCategoryById(transaction.categoryId);

    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;

    Color amountColor;
    String prefix;

    if (isIncome) {
      amountColor = AppColors.income;
      prefix = '+';
    } else if (isTransfer) {
      amountColor = AppColors.transfer;
      prefix = '';
    } else {
      amountColor = AppColors.expense;
      prefix = '-';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (category?.color ?? Colors.grey).withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.2
                        : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  isTransfer
                      ? Icons.swap_horiz
                      : category?.icon ?? Icons.category,
                  color: category?.color ?? Colors.grey,
                ),
              ),
              const SizedBox(width: AppSizes.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTransfer ? 'Transfer' : category?.name ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix${currencyProvider.formatAmount(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    _formatDate(transaction.date),
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
}
