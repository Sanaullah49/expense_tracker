import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/models/transaction_model.dart';
import 'providers/theme_provider.dart';
import 'screens/accounts/accounts_screen.dart';
import 'screens/accounts/add_account_screen.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/budgets/add_budget_screen.dart';
import 'screens/budgets/budgets_screen.dart';
import 'screens/categories/add_category_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/transaction_details_screen.dart';
import 'screens/transactions/transactions_screen.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          },
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final textScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.2,
            );

            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: textScaler),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String lock = '/lock';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String transactionDetails = '/transaction-details';
  static const String accounts = '/accounts';
  static const String addAccount = '/add-account';
  static const String accountDetails = '/account-details';
  static const String budgets = '/budgets';
  static const String addBudget = '/add-budget';
  static const String categories = '/categories';
  static const String addCategory = '/add-category';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String backup = '/backup';
  static const String export = '/export';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    lock: (_) => const LockScreen(),
    home: (_) => const HomeScreen(),
    transactions: (_) => const TransactionsScreen(),
    accounts: (_) => const AccountsScreen(),
    addAccount: (_) => const AddAccountScreen(),
    budgets: (_) => const BudgetsScreen(),
    addBudget: (_) => const AddBudgetScreen(),
    categories: (_) => const CategoriesScreen(),
    statistics: (_) => const StatisticsScreen(),
    settings: (_) => const SettingsScreen(),
    profile: (_) => const ProfileScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case transactionDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TransactionDetailsScreen(
            transactionId: args?['transactionId'] ?? '',
          ),
        );

      case addTransaction:
        final args = settings.arguments as Map<String, dynamic>?;

        final type = args?['type'] as TransactionType?;
        final transaction = args?['transaction'] as TransactionModel?;

        return MaterialPageRoute(
          builder: (_) =>
              AddTransactionScreen(initialType: type, transaction: transaction),
        );

      case addAccount:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddAccountScreen(account: args?['account']),
        );

      case addBudget:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddBudgetScreen(budget: args?['budget']),
        );

      case addCategory:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddCategoryScreen(
            category: args?['category'],
            isIncome: args?['isIncome'] ?? false,
          ),
        );

      default:
        return null;
    }
  }

  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, dynamic>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  static void popToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
  }
}
