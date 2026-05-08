import 'package:flutter/material.dart' hide AnimatedBuilder;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/cards/balance_card.dart';
import '../../widgets/cards/transaction_item.dart';
import '../../widgets/charts/progress_chart_widget.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isShowingLock = false;
  bool _shouldLockOnNextResume = false;

  final List<Widget> _screens = [
    const _HomeTab(),
    const TransactionsScreen(),
    const SizedBox(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<TransactionProvider>().loadTransactions(),
      context.read<AccountProvider>().loadAccounts(),
      context.read<BudgetProvider>().loadBudgets(),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _shouldLockOnNextResume = true;
        break;
      case AppLifecycleState.resumed:
        _lockOnResumeIfNeeded();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _lockOnResumeIfNeeded() async {
    if (!mounted || _isShowingLock || !_shouldLockOnNextResume) return;

    final settings = context.read<SettingsProvider>();
    if (!settings.isLockEnabled) {
      _shouldLockOnNextResume = false;
      return;
    }
    if (settings.shouldSuppressImmediateRelock) {
      _shouldLockOnNextResume = false;
      return;
    }

    _isShowingLock = true;
    _shouldLockOnNextResume = false;
    await Navigator.pushNamed(context, AppRoutes.lock);
    if (mounted) {
      _isShowingLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddOptionsBottomSheet();
              },
              elevation: 0,
              heroTag: 'home_fab',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 0,
        height: 72,
        padding: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _buildNavItem(
              1,
              Icons.receipt_long_outlined,
              Icons.receipt_long_rounded,
              'Transactions',
            ),
            const SizedBox(width: 56),
            _buildNavItem(
              3,
              Icons.pie_chart_outline_rounded,
              Icons.pie_chart_rounded,
              'Stats',
            ),
            _buildNavItem(
              4,
              Icons.settings_outlined,
              Icons.settings_rounded,
              'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final unselectedColor = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (index == 1) {
            context.read<TransactionProvider>().clearFilters();
          }
          setState(() => _currentIndex = index);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : unselectedColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.5,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddOptionsSheet(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with AutomaticKeepAliveClientMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 200 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      context.read<TransactionProvider>().loadTransactions(),
      context.read<AccountProvider>().loadAccounts(),
      context.read<BudgetProvider>().loadBudgets(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _onRefresh,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildGreeting(),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.sm,
                    ),
                    child: _AnimatedBalanceCard(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.sm,
                      AppSizes.md,
                      AppSizes.sm,
                    ),
                    child: _QuickActions(),
                  ),
                ),

                _buildBudgetOverview(),

                _buildRecentTransactions(),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          if (_showBackToTop)
            Positioned(
              bottom: 100,
              right: 16,
              child: _BackToTopButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      titleSpacing: AppSizes.md,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            AppStrings.appName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarIconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 22),
              Consumer<BudgetProvider>(
                builder: (context, budgetProvider, _) {
                  final exceededCount = budgetProvider
                      .getExceededBudgets()
                      .length;
                  final nearLimitCount = budgetProvider
                      .getNearLimitBudgets()
                      .length;
                  final totalAlerts = exceededCount + nearLimitCount;

                  if (totalAlerts > 0) {
                    return Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalAlerts > 9 ? '9+' : '$totalAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          onPressed: () => _showNotificationsSheet(context),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
            child: Consumer<UserProvider>(
              builder: (context, user, _) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primarySoftGradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userProvider.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getMotivationalQuote(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetOverview() {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, _) {
        final activeBudgets = budgetProvider.activeBudgets;

        if (activeBudgets.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final healthStatus = budgetProvider.getBudgetHealth();
        final overallPercentUsed = budgetProvider.overallPercentUsed;
        final healthColor = _getBudgetHealthColor(healthStatus);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.budgets),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        healthColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        healthColor.withValues(alpha: isDark ? 0.08 : 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: healthColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ProgressChartWidget(
                        percentage: overallPercentUsed,
                        size: 70,
                        strokeWidth: 7,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  healthStatus.icon,
                                  color: healthColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    healthStatus.message,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: healthColor,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeBudgets.length} active budget${activeBudgets.length > 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            if (budgetProvider.getExceededBudgets().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${budgetProvider.getExceededBudgets().length} exceeded',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: healthColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: ShimmerTransactionList(itemCount: 3),
            ),
          );
        }

        final transactions = provider.getRecentTransactions(limit: 10);

        if (transactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          AppColors.primary.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start by adding your first transaction',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addTransaction,
                        arguments: {'type': TransactionType.expense},
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: transactions.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<TransactionProvider>().clearFilters();
                        Navigator.pushNamed(context, AppRoutes.transactions);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('See All'),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final transactionIndex = index - 1;
            if (transactionIndex >= transactions.length) {
              return const SizedBox.shrink();
            }

            final transaction = transactions[transactionIndex];

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                4,
                AppSizes.md,
                4,
              ),
              child: TransactionItem(
                transaction: transaction,
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.transactionDetails,
                    arguments: {'transactionId': transaction.id},
                  );

                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _onRefresh();
                    });
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getBudgetHealthColor(BudgetHealthStatus status) {
    switch (status) {
      case BudgetHealthStatus.healthy:
        return AppColors.success;
      case BudgetHealthStatus.warning:
        return AppColors.warning;
      case BudgetHealthStatus.exceeded:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationalQuote() {
    final quotes = [
      'Track wisely, spend smartly.',
      'Every penny counts.',
      'Your financial journey starts here.',
      'Building wealth, one transaction at a time.',
      'Stay on budget, reach your goals.',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  void _showNotificationsSheet(BuildContext context) {
    final budgetProvider = context.read<BudgetProvider>();
    final exceededBudgets = budgetProvider.getExceededBudgets();
    final nearLimitBudgets = budgetProvider.getNearLimitBudgets();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primarySoftGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: Theme.of(context).dividerColor,
              ),

              Expanded(
                child: (exceededBudgets.isEmpty && nearLimitBudgets.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 40,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You\'re all caught up',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All your budgets are on track',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(AppSizes.md),
                        children: [
                          if (exceededBudgets.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Budget Exceeded',
                              AppColors.error,
                            ),
                            ...exceededBudgets.map(
                              (budget) => _buildNotificationTile(
                                context,
                                title: budget.name,
                                subtitle:
                                    'You\'ve exceeded your budget by ${((budget.spent / budget.amount - 1) * 100).toStringAsFixed(0)}%',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                          ],

                          if (nearLimitBudgets.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Near Limit',
                              AppColors.warning,
                            ),
                            ...nearLimitBudgets.map(
                              (budget) => _buildNotificationTile(
                                context,
                                title: budget.name,
                                subtitle:
                                    '${budget.percentUsed.toStringAsFixed(0)}% of budget used',
                                icon: Icons.info_outline_rounded,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.budgets);
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _AppBarIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceMutedDark
                : AppColors.surfaceMutedLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

class _AnimatedBalanceCard extends StatefulWidget {
  @override
  State<_AnimatedBalanceCard> createState() => _AnimatedBalanceCardState();
}

class _AnimatedBalanceCardState extends State<_AnimatedBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: settings.showBalance
            ? const BalanceCard()
            : _HiddenBalanceCard(),
      ),
    );
  }
}

class _HiddenBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Material(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await context
                        .read<SettingsProvider>()
                        .setShowBalance(true);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Show',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '••••••',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Balance hidden',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _QuickActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Income',
          color: AppColors.income,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(
              context,
              AppRoutes.addTransaction,
              arguments: {'type': TransactionType.income},
            );
          },
        ),
        _QuickActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Expense',
          color: AppColors.expense,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(
              context,
              AppRoutes.addTransaction,
              arguments: {'type': TransactionType.expense},
            );
          },
        ),
        _QuickActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer',
          color: AppColors.transfer,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(
              context,
              AppRoutes.addTransaction,
              arguments: {'type': TransactionType.transfer},
            );
          },
        ),
        _QuickActionButton(
          icon: Icons.savings_rounded,
          label: 'Budgets',
          color: AppColors.primary,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRoutes.budgets);
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceMutedDark
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.6)
                  : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOptionsSheet extends StatelessWidget {
  const _AddOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Create New',
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like to add?',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _PrimaryActionCard(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Income',
                    color: AppColors.income,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addTransaction,
                        arguments: {'type': TransactionType.income},
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryActionCard(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Expense',
                    color: AppColors.expense,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addTransaction,
                        arguments: {'type': TransactionType.expense},
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryActionCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transfer',
                    color: AppColors.transfer,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addTransaction,
                        arguments: {'type': TransactionType.transfer},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'More Options',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _SecondaryActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Account',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.addAccount);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionTile(
                    icon: Icons.savings_outlined,
                    label: 'Budget',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.addBudget);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionTile(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.addCategory);
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceMutedDark
                : AppColors.surfaceMutedLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackToTopButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.small(
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.arrow_upward_rounded, size: 18),
        ),
      ),
    );
  }
}
