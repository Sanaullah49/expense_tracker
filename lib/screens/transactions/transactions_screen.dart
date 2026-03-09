import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/date_range_presets.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
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
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              if (!provider.hasFilters || provider.transactions.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Export filtered results',
                onPressed: _showFilteredExportOptions,
              );
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

  Future<void> _showFilteredExportOptions() async {
    final format = await showModalBottomSheet<TransactionExportFormat>(
      context: context,
      builder: (_) => const _FilteredExportSheet(),
    );

    if (format == null || !mounted) return;
    await _exportFilteredTransactions(format);
  }

  Future<void> _exportFilteredTransactions(
    TransactionExportFormat format,
  ) async {
    final transactionProvider = context.read<TransactionProvider>();
    final transactions = List<TransactionModel>.from(
      transactionProvider.transactions,
    );

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No filtered transactions available to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final categoryProvider = context.read<CategoryProvider>();
      final currencyProvider = context.read<CurrencyProvider>();
      final categories = {for (var c in categoryProvider.categories) c.id: c};
      final dateRange =
          transactionProvider.startDate != null &&
              transactionProvider.endDate != null
          ? DateTimeRange(
              start: transactionProvider.startDate!,
              end: transactionProvider.endDate!,
            )
          : null;

      await ExportService.exportTransactions(
        format: format,
        transactions: transactions,
        categories: categories,
        currencySymbol: currencyProvider.currencySymbol,
        periodLabel: DateRangePresetHelper.describeSelection(
          transactionProvider.selectedDateRangePreset,
          dateRange,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Filtered transactions exported ${_exportFormatLabel(format)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _exportFormatLabel(TransactionExportFormat format) {
    switch (format) {
      case TransactionExportFormat.pdf:
        return 'as PDF';
      case TransactionExportFormat.excel:
        return 'as Excel';
      case TransactionExportFormat.csv:
        return 'as CSV';
    }
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  TransactionType? _selectedType;
  TransactionDateRangePreset _selectedDateRangePreset =
      TransactionDateRangePreset.allData;
  DateTimeRange? _customDateRange;

  DateTimeRange? get _selectedDateRange =>
      _selectedDateRangePreset == TransactionDateRangePreset.custom
      ? _customDateRange
      : DateRangePresetHelper.resolveRange(_selectedDateRangePreset);

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _selectedType = provider.selectedType;
    _selectedDateRangePreset = provider.selectedDateRangePreset;
    if (provider.startDate != null && provider.endDate != null) {
      _customDateRange = DateTimeRange(
        start: provider.startDate!,
        end: provider.endDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
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
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: DateRangePresetHelper.presets.map((preset) {
                final isSelected = _selectedDateRangePreset == preset;
                return FilterChip(
                  label: Text(DateRangePresetHelper.chipLabel(preset)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedDateRangePreset = preset);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.18),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
            if (_selectedDateRangePreset ==
                TransactionDateRangePreset.custom) ...[
              const SizedBox(height: AppSizes.md),
              InkWell(
                onTap: _pickCustomRange,
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
                      const Icon(Icons.date_range),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          _customDateRange == null
                              ? 'Select custom range'
                              : DateRangePresetHelper.describeSelection(
                                  TransactionDateRangePreset.custom,
                                  _customDateRange,
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
            ],
            const SizedBox(height: AppSizes.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                'Selected: ${DateRangePresetHelper.describeSelection(_selectedDateRangePreset, _selectedDateRange)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedDateRangePreset ==
                          TransactionDateRangePreset.custom &&
                      _customDateRange == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a custom date range'),
                      ),
                    );
                    return;
                  }

                  final provider = context.read<TransactionProvider>();
                  provider.applyFilters(
                    type: _selectedType,
                    dateRange: _selectedDateRange,
                    dateRangePreset: _selectedDateRangePreset,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final initialRange =
        _customDateRange ??
        DateRangePresetHelper.resolveRange(TransactionDateRangePreset.oneWeek)!;

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
    );

    if (range != null) {
      setState(() => _customDateRange = range);
    }
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

class _FilteredExportSheet extends StatelessWidget {
  const _FilteredExportSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Text(
              'Export Filtered Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export as PDF'),
            subtitle: const Text('Generate a PDF report'),
            onTap: () => Navigator.pop(context, TransactionExportFormat.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Export as Excel'),
            subtitle: const Text('Generate an Excel spreadsheet'),
            onTap: () => Navigator.pop(context, TransactionExportFormat.excel),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: Colors.blue),
            title: const Text('Export as CSV'),
            subtitle: const Text('Generate a CSV file'),
            onTap: () => Navigator.pop(context, TransactionExportFormat.csv),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}
