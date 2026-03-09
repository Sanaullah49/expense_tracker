import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/cards/transaction_item.dart';
import '../../app.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<TransactionProvider>().setSearchQuery(value);
                },
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<TransactionProvider>().setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupedTransactions = provider.getTransactionsGroupedByDate();

          if (groupedTransactions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              final date = groupedTransactions.keys.elementAt(index);
              final transactions = groupedTransactions[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          _getDayTotal(transactions),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...transactions.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: TransactionItem(
                        transaction: t,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.transactionDetails,
                            arguments: {'transactionId': t.id},
                          );

                          if (context.mounted) {
                            context
                                .read<TransactionProvider>()
                                .loadTransactions();
                            context.read<BudgetProvider>().loadBudgets();
                            context.read<AccountProvider>().loadAccounts();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  String _getDayTotal(List<TransactionModel> transactions) {
    final currencyProvider = context.read<CurrencyProvider>();
    double total = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      } else if (t.type == TransactionType.expense) {
        total -= t.amount;
      }
    }
    final prefix = total >= 0 ? '+' : '';
    return '$prefix${currencyProvider.formatAmount(total.abs())}';
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  TransactionType? _selectedType;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _selectedType = provider.selectedType;
    if (provider.startDate != null && provider.endDate != null) {
      _dateRange = DateTimeRange(
        start: provider.startDate!,
        end: provider.endDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<TransactionProvider>().clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _selectedType == null,
                onSelected: (_) => setState(() => _selectedType = null),
              ),
              _buildFilterChip(
                label: 'Income',
                selected: _selectedType == TransactionType.income,
                onSelected: (_) =>
                    setState(() => _selectedType = TransactionType.income),
                color: AppColors.income,
              ),
              _buildFilterChip(
                label: 'Expense',
                selected: _selectedType == TransactionType.expense,
                onSelected: (_) =>
                    setState(() => _selectedType = TransactionType.expense),
                color: AppColors.expense,
              ),
              _buildFilterChip(
                label: 'Transfer',
                selected: _selectedType == TransactionType.transfer,
                onSelected: (_) =>
                    setState(() => _selectedType = TransactionType.transfer),
                color: AppColors.transfer,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.sm),
          InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (range != null) {
                setState(() => _dateRange = range);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    _dateRange != null
                        ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                        : 'Select date range',
                  ),
                  if (_dateRange != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _dateRange = null),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final provider = context.read<TransactionProvider>();
                provider.setType(_selectedType);
                if (_dateRange != null) {
                  provider.setDateRange(_dateRange!.start, _dateRange!.end);
                } else {
                  provider.clearFilters();
                  provider.setType(_selectedType);
                }
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: (color ?? AppColors.primary).withValues(alpha: 0.2),
      checkmarkColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? (color ?? AppColors.primary) : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }
}
