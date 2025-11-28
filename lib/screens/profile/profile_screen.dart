import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/account_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _avatarPath;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _avatarPath = user.avatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body:
          Consumer4<
            UserProvider,
            TransactionProvider,
            AccountProvider,
            CurrencyProvider
          >(
            builder:
                (
                  context,
                  userProvider,
                  transactionProvider,
                  accountProvider,
                  currencyProvider,
                  _,
                ) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _isEditing ? _pickImage : null,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage: _avatarPath != null
                                      ? FileImage(File(_avatarPath!))
                                      : null,
                                  child: _avatarPath == null
                                      ? Text(
                                          userProvider.initials,
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),

                        if (_isEditing) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ] else ...[
                          Text(
                            userProvider.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (userProvider.user?.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              userProvider.user!.email!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: AppSizes.xl),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Balance',
                                currencyProvider.formatAmount(
                                  accountProvider.totalBalance,
                                ),
                                Icons.account_balance_wallet,
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: _buildStatCard(
                                'Accounts',
                                accountProvider.accountCount.toString(),
                                Icons.credit_card,
                                AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Income',
                                currencyProvider.formatAmount(
                                  transactionProvider.totalIncome,
                                ),
                                Icons.arrow_downward,
                                AppColors.income,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: _buildStatCard(
                                'Total Expense',
                                currencyProvider.formatAmount(
                                  transactionProvider.totalExpense,
                                ),
                                Icons.arrow_upward,
                                AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xl),

                        Builder(
                          builder: (context) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            final containerColor = isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100;
                            final contentColor = isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade600;

                            return Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: containerColor,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: contentColor,
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Member since',
                                        style: TextStyle(
                                          color: contentColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(
                                          userProvider.user?.createdAt ??
                                              DateTime.now(),
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
          ),
    );
  }

  Widget _buildStatCard(
    String label,
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _saveProfile() async {
    await context.read<UserProvider>().updateUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      avatar: _avatarPath,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
