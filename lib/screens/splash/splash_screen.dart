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
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _buildBlob(220, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildBlob(280, Colors.white.withValues(alpha: 0.06)),
            ),
            Positioned(
              top: 120,
              left: 30,
              child: _buildBlob(20, Colors.white.withValues(alpha: 0.4)),
            ),
            Positioned(
              top: 200,
              right: 50,
              child: _buildBlob(8, Colors.white.withValues(alpha: 0.6)),
            ),
            Positioned(
              bottom: 200,
              right: 80,
              child: _buildBlob(14, Colors.white.withValues(alpha: 0.3)),
            ),
            SafeArea(
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
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppColors.primaryGradient.createShader(
                                      bounds,
                                    ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: const Text(
                              AppStrings.appName,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Text(
                              AppStrings.appTagline,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),

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
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      children: [
        const _LoadingDots(),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _loadingMessage,
            key: ValueKey(_loadingMessage),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Something went wrong',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _hasError = false;
              _errorMessage = null;
            });
            _initializeApp();
          },
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final progress = (_controller.value - i * 0.15) % 1.0;
              final scale = 0.6 + 0.4 * (1 - (progress - 0.3).abs() * 3.3).clamp(0.0, 1.0);
              final opacity = 0.4 + 0.6 * (1 - (progress - 0.3).abs() * 3.3).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
