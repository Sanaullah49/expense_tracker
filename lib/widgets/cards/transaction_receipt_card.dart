import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';

class TransactionReceiptCard extends StatelessWidget {
  final TransactionModel transaction;
  final String currencySymbol;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const TransactionReceiptCard({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Expense Tracker',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Transaction Receipt',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 32),

          _buildRow(context, 'Title', transaction.title),
          _buildDivider(context),
          _buildRow(
            context,
            'Date',
            DateFormat('MMM d, yyyy • h:mm a').format(transaction.date),
          ),
          _buildDivider(context),
          _buildRow(context, 'Category', categoryName),
          _buildDivider(context),
          _buildRow(context, 'Type', transaction.type.name.toUpperCase()),

          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            _buildDivider(context),
            _buildRow(context, 'Note', transaction.note!),
          ],

          const SizedBox(height: 32),

          Text(
            'Generated automatically',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Theme.of(context).dividerColor),
    );
  }
}
