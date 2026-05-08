import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, CurrencyProvider>(
      builder: (context, transactionProvider, currencyProvider, _) {
        final allTransactions = transactionProvider.allTransactions;
        final income = allTransactions
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final expense = allTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final balance = income - expense;

        return Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1F8F), Color(0xFF1A0F6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A0F6B).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currencyProvider.formatAmount(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      amount: currencyProvider.formatAmount(income),
                      tint: const Color(0xFF55EFC4),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: _buildStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expense',
                      amount: currencyProvider.formatAmount(expense),
                      tint: const Color(0xFFFF7675),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String amount,
    required Color tint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: tint, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
