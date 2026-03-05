import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 1;
  int _touchedIndex = -1;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).hintColor,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoriesTab(),
                _buildTrendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          Row(
            children: [
              _buildPeriodButton(0, 'Week'),
              const SizedBox(width: AppSizes.sm),
              _buildPeriodButton(1, 'Month'),
              const SizedBox(width: AppSizes.sm),
              _buildPeriodButton(2, 'Year'),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousPeriod,
              ),
              TextButton(
                onPressed: _selectDate,
                child: Text(
                  _getPeriodLabel(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextPeriod,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(int index, String label) {
    final isSelected = _selectedPeriod == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF2D2D44) : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.grey.shade700),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<TransactionProvider, CurrencyProvider>(
      builder: (context, transactionProvider, currencyProvider, _) {
        final dateRange = _getDateRange();
        final transactions = transactionProvider.getTransactionsForDateRange(
          dateRange.start,
          dateRange.end,
        );

        final income = transactions
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (sum, t) => sum + t.amount);

        final expense = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (sum, t) => sum + t.amount);

        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(income, expense, currencyProvider),
              const SizedBox(height: AppSizes.lg),

              const Text(
                'Income vs Expense',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(height: 300, child: _buildBarChart(transactions)),
              const SizedBox(height: AppSizes.lg),

              _buildBalanceFlow(income, expense, currencyProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(
    double income,
    double expense,
    CurrencyProvider currencyProvider,
  ) {
    final balance = income - expense;
    final savingsRate = income > 0 ? ((income - expense) / income * 100) : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Income',
                currencyProvider.formatAmount(income),
                AppColors.income,
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _buildSummaryCard(
                'Expense',
                currencyProvider.formatAmount(expense),
                AppColors.expense,
                Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Balance',
                currencyProvider.formatAmount(balance),
                balance >= 0 ? AppColors.success : AppColors.error,
                Icons.account_balance,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _buildSummaryCard(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                savingsRate > 20 ? AppColors.success : AppColors.warning,
                Icons.savings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<TransactionModel> transactions) {
    final data = _prepareBarChartData(transactions);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            data.fold<double>(0, (max, group) {
              final maxValue = group.barRods.fold<double>(
                0,
                (m, rod) => rod.toY > m ? rod.toY : m,
              );
              return maxValue > max ? maxValue : max;
            }) *
            1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.grey.shade800,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${context.read<CurrencyProvider>().formatAmount(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getBarLabel(value.toInt()),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        barGroups: data,
      ),
    );
  }

  List<BarChartGroupData> _prepareBarChartData(
    List<TransactionModel> transactions,
  ) {
    final Map<int, Map<String, double>> groupedData = {};

    if (_selectedPeriod == 0) {
      for (int i = 0; i < 7; i++) {
        groupedData[i] = {'income': 0, 'expense': 0};
      }

      for (var t in transactions) {
        final dayIndex = t.date.weekday - 1;
        if (t.type == TransactionType.income) {
          groupedData[dayIndex]!['income'] =
              groupedData[dayIndex]!['income']! + t.amount;
        } else if (t.type == TransactionType.expense) {
          groupedData[dayIndex]!['expense'] =
              groupedData[dayIndex]!['expense']! + t.amount;
        }
      }
    } else if (_selectedPeriod == 1) {
      for (int i = 0; i < 5; i++) {
        groupedData[i] = {'income': 0, 'expense': 0};
      }

      for (var t in transactions) {
        final weekIndex = ((t.date.day - 1) / 7).floor();
        if (weekIndex < 5) {
          if (t.type == TransactionType.income) {
            groupedData[weekIndex]!['income'] =
                groupedData[weekIndex]!['income']! + t.amount;
          } else if (t.type == TransactionType.expense) {
            groupedData[weekIndex]!['expense'] =
                groupedData[weekIndex]!['expense']! + t.amount;
          }
        }
      }
    } else {
      for (int i = 0; i < 12; i++) {
        groupedData[i] = {'income': 0, 'expense': 0};
      }

      for (var t in transactions) {
        final monthIndex = t.date.month - 1;
        if (t.type == TransactionType.income) {
          groupedData[monthIndex]!['income'] =
              groupedData[monthIndex]!['income']! + t.amount;
        } else if (t.type == TransactionType.expense) {
          groupedData[monthIndex]!['expense'] =
              groupedData[monthIndex]!['expense']! + t.amount;
        }
      }
    }

    return groupedData.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value['income']!,
            color: AppColors.income,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: entry.value['expense']!,
            color: AppColors.expense,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  String _getBarLabel(int index) {
    if (_selectedPeriod == 0) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[index];
    } else if (_selectedPeriod == 1) {
      return 'W${index + 1}';
    } else {
      const months = [
        'J',
        'F',
        'M',
        'A',
        'M',
        'J',
        'J',
        'A',
        'S',
        'O',
        'N',
        'D',
      ];
      return months[index];
    }
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildBalanceFlow(
    double income,
    double expense,
    CurrencyProvider currencyProvider,
  ) {
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: balance >= 0
              ? [
                  AppColors.success.withValues(alpha: 0.1),
                  AppColors.success.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.error.withValues(alpha: 0.1),
                  AppColors.error.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: balance >= 0
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cash Flow',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(
                balance >= 0 ? Icons.trending_up : Icons.trending_down,
                color: balance >= 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            currencyProvider.formatAmount(balance.abs()),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
          Text(
            balance >= 0 ? 'Surplus' : 'Deficit',
            style: TextStyle(
              color: balance >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Consumer3<TransactionProvider, CategoryProvider, CurrencyProvider>(
      builder:
          (
            context,
            transactionProvider,
            categoryProvider,
            currencyProvider,
            _,
          ) {
            final dateRange = _getDateRange();
            final transactions = transactionProvider
                .getTransactionsForDateRange(dateRange.start, dateRange.end)
                .where((t) => t.type == TransactionType.expense)
                .toList();

            if (transactions.isEmpty) {
              return const Center(child: Text('No expense data available'));
            }

            final Map<String, double> categoryTotals = {};
            for (var t in transactions) {
              categoryTotals[t.categoryId] =
                  (categoryTotals[t.categoryId] ?? 0) + t.amount;
            }

            final sortedCategories = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final total = sortedCategories.fold<double>(
              0,
              (sum, entry) => sum + entry.value,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                        sections: _buildPieChartSections(
                          sortedCategories,
                          categoryProvider,
                          total,
                        ),
                        centerSpaceRadius: 60,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  ...sortedCategories.take(10).toList().asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final categoryId = entry.value.key;
                    final amount = entry.value.value;
                    final category = categoryProvider.getCategoryById(
                      categoryId,
                    );
                    final percentage = (amount / total * 100);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: _touchedIndex == index
                            ? category?.color.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: _touchedIndex == index
                              ? category?.color ?? Colors.grey
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  category?.color.withValues(alpha: 0.2) ??
                                  Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
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
                                  category?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                    category?.color ?? Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyProvider.formatAmount(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
    );
  }

  Widget _buildTrendsTab() {
    return Consumer2<TransactionProvider, CurrencyProvider>(
      builder: (context, transactionProvider, currencyProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spending Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                height: 250,
                child: _buildLineChart(transactionProvider),
              ),
              const SizedBox(height: AppSizes.lg),

              _buildAverageStats(transactionProvider, currencyProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineChart(TransactionProvider transactionProvider) {
    final data = _prepareLineChartData(transactionProvider);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _getLineChartLabel(value.toInt()),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: data,
      ),
    );
  }

  List<LineChartBarData> _prepareLineChartData(
    TransactionProvider transactionProvider,
  ) {
    final dateRange = _getDateRange();
    final transactions = transactionProvider.getTransactionsForDateRange(
      dateRange.start,
      dateRange.end,
    );

    final Map<int, double> incomeData = {};
    final Map<int, double> expenseData = {};

    if (_selectedPeriod == 0) {
      for (int i = 0; i < 7; i++) {
        incomeData[i] = 0;
        expenseData[i] = 0;
      }

      for (var t in transactions) {
        final dayIndex = t.date.difference(dateRange.start).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          if (t.type == TransactionType.income) {
            incomeData[dayIndex] = incomeData[dayIndex]! + t.amount;
          } else if (t.type == TransactionType.expense) {
            expenseData[dayIndex] = expenseData[dayIndex]! + t.amount;
          }
        }
      }
    } else if (_selectedPeriod == 1) {
      final daysInMonth = dateRange.end.difference(dateRange.start).inDays + 1;
      for (int i = 0; i < daysInMonth; i++) {
        incomeData[i] = 0;
        expenseData[i] = 0;
      }

      for (var t in transactions) {
        final dayIndex = t.date.difference(dateRange.start).inDays;
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          if (t.type == TransactionType.income) {
            incomeData[dayIndex] = incomeData[dayIndex]! + t.amount;
          } else if (t.type == TransactionType.expense) {
            expenseData[dayIndex] = expenseData[dayIndex]! + t.amount;
          }
        }
      }
    } else {
      for (int i = 0; i < 12; i++) {
        incomeData[i] = 0;
        expenseData[i] = 0;
      }

      for (var t in transactions) {
        final monthIndex = t.date.month - 1;
        if (t.type == TransactionType.income) {
          incomeData[monthIndex] = incomeData[monthIndex]! + t.amount;
        } else if (t.type == TransactionType.expense) {
          expenseData[monthIndex] = expenseData[monthIndex]! + t.amount;
        }
      }
    }

    return [
      LineChartBarData(
        spots: incomeData.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        color: AppColors.income,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.income.withValues(alpha: 0.1),
        ),
      ),
      LineChartBarData(
        spots: expenseData.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        color: AppColors.expense,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.expense.withValues(alpha: 0.1),
        ),
      ),
    ];
  }

  String _getLineChartLabel(int index) {
    if (_selectedPeriod == 0) {
      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return index < days.length ? days[index] : '';
    } else if (_selectedPeriod == 1) {
      return (index % 5 == 0) ? '${index + 1}' : '';
    } else {
      const months = [
        'J',
        'F',
        'M',
        'A',
        'M',
        'J',
        'J',
        'A',
        'S',
        'O',
        'N',
        'D',
      ];
      return index < months.length ? months[index] : '';
    }
  }

  Widget _buildAverageStats(
    TransactionProvider transactionProvider,
    CurrencyProvider currencyProvider,
  ) {
    final dateRange = _getDateRange();
    final transactions = transactionProvider.getTransactionsForDateRange(
      dateRange.start,
      dateRange.end,
    );

    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final double avgDaily = expenses.isNotEmpty
        ? expenses.fold<double>(0, (sum, t) => sum + t.amount) /
              dateRange.end.difference(dateRange.start).inDays
        : 0;

    final largestExpense = expenses.isNotEmpty
        ? expenses.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg. Daily Expense',
                currencyProvider.formatAmount(avgDaily),
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _buildStatCard(
                'Total Transactions',
                transactions.length.toString(),
                Icons.receipt,
                Colors.purple,
              ),
            ),
          ],
        ),
        if (largestExpense != null) ...[
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Largest Expense',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        largestExpense.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyProvider.formatAmount(largestExpense.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSizes.sm),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, double>> categories,
    CategoryProvider categoryProvider,
    double total,
  ) {
    return categories.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final categoryId = entry.value.key;
      final amount = entry.value.value;
      final category = categoryProvider.getCategoryById(categoryId);
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;

      return PieChartSectionData(
        color: category?.color ?? Colors.grey,
        value: amount,
        title: isTouched ? '${(amount / total * 100).toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  DateTimeRange _getDateRange() {
    final now = _selectedDate;

    switch (_selectedPeriod) {
      case 0:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day + 6,
            23,
            59,
            59,
          ),
        );

      case 1:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );

      case 2:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );

      default:
        return DateTimeRange(start: now, end: now);
    }
  }

  String _getPeriodLabel() {
    final dateFormat = _selectedPeriod == 0
        ? DateFormat('MMM d')
        : _selectedPeriod == 1
        ? DateFormat('MMMM yyyy')
        : DateFormat('yyyy');

    if (_selectedPeriod == 0) {
      final range = _getDateRange();
      return '${DateFormat('MMM d').format(range.start)} - ${DateFormat('MMM d').format(range.end)}';
    }

    return dateFormat.format(_selectedDate);
  }

  void _previousPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case 0:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case 1:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
          break;
        case 2:
          _selectedDate = DateTime(_selectedDate.year - 1);
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case 0:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case 1:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
          break;
        case 2:
          _selectedDate = DateTime(_selectedDate.year + 1);
          break;
      }
    });
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
