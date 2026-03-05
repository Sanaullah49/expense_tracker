import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/recurring_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late SettingsProvider settingsProvider;

  String _loadingMessage = 'Initializing...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _updateLoadingMessage('Loading settings...');
      if (mounted) {
        settingsProvider = context.read<SettingsProvider>();
      }
      await settingsProvider.waitForInitialization();
      await Future.delayed(const Duration(milliseconds: 100));

      _updateLoadingMessage('Loading categories...');
      if (mounted) {
        await context.read<CategoryProvider>().loadCategories();
      }
      await Future.delayed(const Duration(milliseconds: 200));
      await RecurringService().checkAndGenerateRecurringTransactions();

      _updateLoadingMessage('Loading accounts...');
      if (mounted) {
        await context.read<AccountProvider>().loadAccounts();
      }
      await Future.delayed(const Duration(milliseconds: 200));

      _updateLoadingMessage('Loading transactions...');
      if (mounted) {
        await context.read<TransactionProvider>().loadTransactions();
      }
      await Future.delayed(const Duration(milliseconds: 200));

      _updateLoadingMessage('Loading budgets...');
      if (mounted) {
        await context.read<BudgetProvider>().loadBudgets();
      }
      await Future.delayed(const Duration(milliseconds: 200));

      _updateLoadingMessage('Setting up notifications...');
      await NotificationService().requestPermissions();

      if (settingsProvider.autoBackupEnabled) {
        _updateLoadingMessage('Checking backups...');
        await BackupService().performAutoBackupIfNeeded(
          settingsProvider.autoBackupEnabled,
          settingsProvider.autoBackupRetention,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final openCount = prefs.getInt('app_open_count') ?? 0;
      await prefs.setInt('app_open_count', openCount + 1);

      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      _updateLoadingMessage('Almost ready...');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        bool isLockEnabled = settingsProvider.hasPin;
        if (!isLockEnabled && settingsProvider.biometricEnabled) {
          final localAuth = LocalAuthentication();
          final canCheck = await localAuth.canCheckBiometrics;
          final isSupported = await localAuth.isDeviceSupported();

          if (canCheck && isSupported) {
            isLockEnabled = true;
          } else {
            await settingsProvider.setBiometricEnabled(false);
          }
        }
        if (!mounted) return;

        debugPrint('=== App Lock Check ===');
        debugPrint('Is first time: $isFirstTime');
        debugPrint('Has PIN: ${settingsProvider.hasPin}');
        debugPrint('Biometric enabled: ${settingsProvider.biometricEnabled}');
        debugPrint('Is lock enabled: $isLockEnabled');

        String targetRoute;
        if (isFirstTime) {
          targetRoute = AppRoutes.onboarding;
          debugPrint('Navigating to: onboarding');
        } else if (isLockEnabled) {
          targetRoute = AppRoutes.lock;
          debugPrint('Navigating to: lock screen');
        } else {
          targetRoute = AppRoutes.home;
          debugPrint('Navigating to: home');
        }

        Navigator.pushReplacementNamed(context, targetRoute);
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _updateLoadingMessage(String message) {
    if (mounted) {
      setState(() => _loadingMessage = message);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Text(
                          AppStrings.appTagline,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      if (_hasError)
                        _buildErrorWidget()
                      else
                        _buildLoadingWidget(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          _loadingMessage,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          'Something went wrong',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            setState(() {
              _hasError = false;
              _errorMessage = null;
            });
            _initializeApp();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
