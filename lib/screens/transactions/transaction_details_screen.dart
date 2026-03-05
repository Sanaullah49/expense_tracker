import 'dart:io';
import '../../core/services/screenshot_service.dart';
import '../../data/models/category_model.dart';
import '../../widgets/cards/transaction_receipt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/dialogs/confirm_dialog.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      TransactionProvider,
      CategoryProvider,
      AccountProvider,
      CurrencyProvider
    >(
      builder:
          (
            context,
            transactionProvider,
            categoryProvider,
            accountProvider,
            currencyProvider,
            _,
          ) {
            final transaction = transactionProvider.getTransactionById(
              widget.transactionId,
            );

            if (transaction == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Transaction')),
                body: isDeleting
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(child: Text('Transaction not found')),
              );
            }

            final category = categoryProvider.getCategoryById(
              transaction.categoryId,
            );
            final account = accountProvider.getAccountById(
              transaction.accountId,
            );
            final toAccount = transaction.toAccountId != null
                ? accountProvider.getAccountById(transaction.toAccountId!)
                : null;

            final isIncome = transaction.type == TransactionType.income;
            final isTransfer = transaction.type == TransactionType.transfer;
            final isExpense = transaction.type == TransactionType.expense;

            Color typeColor;
            String typeLabel;
            IconData typeIcon;

            if (isIncome) {
              typeColor = AppColors.income;
              typeLabel = 'Income';
              typeIcon = Icons.arrow_downward;
            } else if (isTransfer) {
              typeColor = AppColors.transfer;
              typeLabel = 'Transfer';
              typeIcon = Icons.swap_horiz;
            } else {
              typeColor = AppColors.expense;
              typeLabel = 'Expense';
              typeIcon = Icons.arrow_upward;
            }

            const fgColor = Colors.white;

            final popupIconColor = Theme.of(context).colorScheme.onSurface;

            return Scaffold(
              backgroundColor: typeColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,

                iconTheme: const IconThemeData(color: fgColor),

                titleTextStyle: const TextStyle(
                  color: fgColor,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),

                systemOverlayStyle: SystemUiOverlayStyle.light,

                title: const Text('Transaction Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareTransaction(
                      context,
                      transaction,
                      currencyProvider,
                      category,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: fgColor),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editTransaction(context, transaction);
                          break;
                        case 'duplicate':
                          _duplicateTransaction(context, transaction);
                          break;
                        case 'delete':
                          _deleteTransaction(transaction);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: popupIconColor),
                            const SizedBox(width: 12),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_outlined, color: popupIconColor),
                            const SizedBox(width: 12),
                            const Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.error),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: fgColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                typeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          '${isExpense
                              ? '-'
                              : isIncome
                              ? '+'
                              : ''}${currencyProvider.formatAmount(transaction.amount)}',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          transaction.title,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusXl),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        children: [
                          _buildDetailItem(
                            context,
                            icon: Icons.calendar_today,
                            label: 'Date & Time',
                            value: DateFormat(
                              'EEEE, MMMM d, yyyy • h:mm a',
                            ).format(transaction.date),
                          ),

                          if (!isTransfer && category != null)
                            _buildDetailItem(
                              context,
                              icon: category.icon,
                              iconColor: category.color,
                              label: 'Category',
                              value: category.name,
                            ),

                          if (account != null)
                            _buildDetailItem(
                              context,
                              icon: account.icon,
                              iconColor: account.color,
                              label: isTransfer ? 'From Account' : 'Account',
                              value: account.name,
                            ),

                          if (isTransfer && toAccount != null)
                            _buildDetailItem(
                              context,
                              icon: toAccount.icon,
                              iconColor: toAccount.color,
                              label: 'To Account',
                              value: toAccount.name,
                            ),

                          if (transaction.note != null &&
                              transaction.note!.isNotEmpty)
                            _buildDetailItem(
                              context,
                              icon: Icons.note_outlined,
                              label: 'Note',
                              value: transaction.note!,
                            ),

                          if (transaction.receiptImage != null) ...[
                            const SizedBox(height: AppSizes.md),
                            const Text(
                              'Receipt',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              child: Image.file(
                                File(transaction.receiptImage!),
                                fit: BoxFit.cover,
                                height: 200,
                                width: double.infinity,
                                cacheWidth: 600,
                                errorBuilder: (_, _, _) => Container(
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 48),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSizes.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildMetaRow(
                                  context,
                                  'Created',
                                  _formatDateTime(transaction.createdAt),
                                ),
                                if (transaction.updatedAt !=
                                    transaction.createdAt) ...[
                                  const Divider(),
                                  _buildMetaRow(
                                    context,
                                    'Last Modified',
                                    _formatDateTime(transaction.updatedAt),
                                  ),
                                ],
                                const Divider(),
                                _buildMetaRow(
                                  context,
                                  'Transaction ID',
                                  transaction.id.substring(0, 8).toUpperCase(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSizes.xl),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _deleteTransaction(transaction),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _editTransaction(context, transaction),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: typeColor,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor ?? Colors.grey.shade600),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  void _editTransaction(BuildContext context, TransactionModel transaction) {
    Navigator.pushNamed(
      context,
      AppRoutes.addTransaction,
      arguments: {'transaction': transaction},
    );
  }

  void _duplicateTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final duplicated = TransactionModel(
      id: '',
      title: '${transaction.title} (Copy)',
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      date: DateTime.now(),
      note: transaction.note,
    );

    final success = await transactionProvider.addTransaction(duplicated);

    if (success) {
      await accountProvider.recalculateAllBalances();

      if (duplicated.type == TransactionType.expense) {
        await budgetProvider.recalculateCategoryBudgets(duplicated.categoryId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction duplicated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?',
      confirmText: 'Delete',
      isDangerous: true,
      icon: Icons.delete_outline,
    );

    if (confirm != true) return;

    setState(() => isDeleting = true);

    try {
      if (mounted) {
        final transactionProvider = context.read<TransactionProvider>();
        final accountProvider = context.read<AccountProvider>();
        final budgetProvider = context.read<BudgetProvider>();

        final success = await transactionProvider.deleteTransaction(transaction.id);
        if (!success) {
          if (mounted) {
            setState(() => isDeleting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete transaction'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        await accountProvider.recalculateAllBalances();

        if (transaction.type == TransactionType.expense) {
          await budgetProvider.recalculateCategoryBudgets(
            transaction.categoryId,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _shareTransaction(
    BuildContext context,
    TransactionModel transaction,
    CurrencyProvider currencyProvider,
    CategoryModel? category,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: ScreenshotService.key,
              child: TransactionReceiptCard(
                transaction: transaction,
                currencySymbol: currencyProvider.currencySymbol,
                categoryName: category?.name ?? 'Uncategorized',
                categoryIcon: category?.icon ?? Icons.category,
                categoryColor: category?.color ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.close, color: Colors.black),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: () {
                    ScreenshotService.captureAndShare(
                      context,
                      'transaction_${transaction.id}',
                    );
                    Navigator.pop(context);
                  },
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.share, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
