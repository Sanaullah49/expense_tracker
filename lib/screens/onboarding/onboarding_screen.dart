import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Track Your Expenses',
      description:
          'Keep track of all your daily expenses and income with ease. Categorize transactions for better insights.',
      icon: Icons.receipt_long_rounded,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Set Budgets',
      description:
          'Create budgets for different categories and get notified when you\'re close to exceeding them.',
      icon: Icons.savings_rounded,
      color: AppColors.secondary,
    ),
    OnboardingPage(
      title: 'Analyze Your Spending',
      description:
          'View detailed statistics and charts to understand where your money goes and make better financial decisions.',
      icon: Icons.pie_chart_rounded,
      color: AppColors.income,
    ),
    OnboardingPage(
      title: 'Secure & Private',
      description:
          'Your financial data stays on your device. Protect it with biometric authentication for extra security.',
      icon: Icons.shield_rounded,
      color: AppColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;
    final activeColor = _pages[_currentPage].color;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expense Tracker',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          theme.textTheme.bodyMedium?.color,
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPageView(page: _pages[index]);
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 28 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? activeColor
                        : activeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                0,
                AppSizes.lg,
                AppSizes.lg,
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(56, 56),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1.2,
                          ),
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLastPage) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLastPage ? 'Get Started' : 'Continue'),
                            const SizedBox(width: 6),
                            Icon(
                              isLastPage
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: page.color.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: page.color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        page.color,
                        page.color.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(page.icon, size: 60, color: Colors.white),
                ),

                Positioned(
                  top: 30,
                  right: 30,
                  child: _Sparkle(
                    color: page.color.withValues(alpha: 0.4),
                    size: 12,
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 20,
                  child: _Sparkle(
                    color: page.color.withValues(alpha: 0.5),
                    size: 8,
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 30,
                  child: _Sparkle(
                    color: page.color.withValues(alpha: 0.3),
                    size: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 26,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            page.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final Color color;
  final double size;

  const _Sparkle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
