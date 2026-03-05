import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/cards/transaction_item.dart';
import 'add_account_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final AccountModel account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late AccountModel _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    final transactions = transactionProvider.allTransactions
        .where(
          (t) => t.accountId == _account.id || t.toAccountId == _account.id,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(_account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editAccount(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'set_default':
                  _setAsDefault(context);
                  break;
                case 'delete':
                  _deleteAccount(context);
                  break;
              }
            },
            itemBuilder: (_) => [
              if (!_account.isDefault)
                const PopupMenuItem(
                  value: 'set_default',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline),
                      SizedBox(width: 12),
                      Text('Set as Default'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAccountInfoCard(currencyProvider),

          _buildStatsRow(transactions, currencyProvider),

          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${transactions.length} items',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyTransactions()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: TransactionItem(
                          transaction: transactions[index],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(CurrencyProvider currencyProvider) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: _account.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _account.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _account.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Icon(_account.icon, size: 32, color: _account.color),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _account.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_account.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _account.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: _account.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _account.typeLabel,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyProvider.formatAmount(_account.balance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _account.balance >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Initial Balance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyProvider.formatAmount(_account.initialBalance),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    List<TransactionModel> transactions,
    CurrencyProvider currencyProvider,
  ) {
    double income = 0;
    double expense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income && t.accountId == _account.id) {
        income += t.amount;
      } else if (t.type == TransactionType.expense &&
          t.accountId == _account.id) {
        expense += t.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Income',
              currencyProvider.formatAmount(income),
              AppColors.income,
              Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _buildStatCard(
              'Expense',
              currencyProvider.formatAmount(expense),
              AppColors.expense,
              Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _editAccount(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAccountScreen(account: _account)),
    );

    if (context.mounted) {
      final provider = context.read<AccountProvider>();
      await provider.loadAccounts();
      final updated = provider.getAccountById(_account.id);
      if (updated != null) {
        setState(() => _account = updated);
      }
    }
  }

  void _setAsDefault(BuildContext context) async {
    await context.read<AccountProvider>().setDefault(_account.id);
    if (context.mounted) {
      setState(() {
        _account = _account.copyWith(isDefault: true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set as default account'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this account? All associated transactions will also be deleted.',
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

    if (confirm == true && context.mounted) {
      final success = await context.read<AccountProvider>().deleteAccount(
        _account.id,
      );
      if (success && context.mounted) {
        await Future.wait([
          context.read<TransactionProvider>().loadTransactions(),
          context.read<BudgetProvider>().loadBudgets(),
        ]);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete account'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
