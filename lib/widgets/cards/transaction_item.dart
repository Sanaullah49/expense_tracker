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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

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

    final categoryColor = category?.color ?? Colors.grey;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.6)
                : AppColors.borderLight.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          splashColor: categoryColor.withValues(alpha: 0.08),
          highlightColor: categoryColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: isDark ? 0.25 : 0.16),
                        categoryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isTransfer
                        ? Icons.swap_horiz_rounded
                        : category?.icon ?? Icons.category_rounded,
                    color: categoryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isTransfer
                                  ? 'Transfer'
                                  : category?.name ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$prefix${currencyProvider.formatAmount(transaction.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: amountColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
