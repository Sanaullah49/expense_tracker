import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/export_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import '../backup/backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            _buildSectionHeader('General'),
            _buildThemeSettings(),
            _buildCurrencySettings(),
            _buildLanguageSettings(),
            const SizedBox(height: AppSizes.lg),

            _buildSectionHeader('Data'),
            _buildSettingsTile(
              icon: Icons.category_outlined,
              title: 'Categories',
              subtitle: 'Manage transaction categories',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.categories);
              },
            ),
            _buildSettingsTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Accounts',
              subtitle: 'Manage your accounts',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.accounts);
              },
            ),
            _buildBackupRestoreSettings(),
            _buildExportSettings(),
            const SizedBox(height: AppSizes.lg),

            _buildSectionHeader('Security'),
            _buildBiometricSettings(),
            _buildPinSettings(),
            _buildShowBalanceSettings(),
            const SizedBox(height: AppSizes.lg),

            _buildSectionHeader('Notifications'),
            _buildNotificationSettings(),
            _buildBudgetAlertSettings(),
            _buildDailyReminderSettings(),
            const SizedBox(height: AppSizes.lg),

            _buildSectionHeader('About'),
            _buildSettingsTile(
              icon: Icons.star_outline,
              title: 'Rate App',
              subtitle: 'Rate us on the store',
              onTap: _rateApp,
            ),
            _buildSettingsTile(
              icon: Icons.share_outlined,
              title: 'Share App',
              subtitle: 'Share with friends',
              onTap: _shareApp,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: _showPrivacyPolicy,
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: _showTermsOfService,
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              trailing: const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSizes.xl),

            _buildSectionHeader('Danger Zone', color: AppColors.error),
            _buildSettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Delete All Data',
              titleColor: AppColors.error,
              subtitle: 'Permanently delete all your data',
              onTap: _deleteAllData,
            ),

            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm, top: AppSizes.sm),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Icon(icon, color: titleColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing:
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return _buildSettingsTile(
          icon: Icons.palette_outlined,
          title: 'Theme',
          subtitle: _getThemeModeLabel(themeProvider.themeMode),
          onTap: () => _showThemePicker(themeProvider),
        );
      },
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemePicker(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Text(
                'Select Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildThemeOption(
              themeProvider,
              ThemeMode.system,
              'System',
              Icons.brightness_auto,
            ),
            _buildThemeOption(
              themeProvider,
              ThemeMode.light,
              'Light',
              Icons.light_mode,
            ),
            _buildThemeOption(
              themeProvider,
              ThemeMode.dark,
              'Dark',
              Icons.dark_mode,
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeProvider themeProvider,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCurrencySettings() {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, _) {
        return _buildSettingsTile(
          icon: Icons.attach_money,
          title: 'Currency',
          subtitle:
              '${currencyProvider.currencyCode} (${currencyProvider.currencySymbol})',
          onTap: () {
            final hasTransactions = context
                .read<TransactionProvider>()
                .transactions
                .isNotEmpty;

            if (hasTransactions) {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.currency_exchange,
                            size: 32,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),

                        const Text(
                          'Change Currency?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.md),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontFamily: 'Poppins',
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'This will only change the symbol displayed (e.g. \$ to €).\n\n',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const TextSpan(
                                text:
                                    'It will NOT convert your existing transaction amounts.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showCurrencyPicker(currencyProvider);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                  ),
                                ),
                                child: const Text('Proceed'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              _showCurrencyPicker(currencyProvider);
            }
          },
        );
      },
    );
  }

  void _showCurrencyPicker(CurrencyProvider currencyProvider) {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        currencyProvider.setCurrency(currency.code, currency.symbol);
      },
      favorite: ['USD', 'EUR', 'GBP', 'INR', 'JPY'],
    );
  }

  Widget _buildLanguageSettings() {
    return _buildSettingsTile(
      icon: Icons.language,
      title: 'Language',
      subtitle: 'English',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('More languages coming soon!')),
        );
      },
    );
  }

  Widget _buildBackupRestoreSettings() {
    return _buildSettingsTile(
      icon: Icons.cloud_upload_outlined,
      title: 'Backup & Restore',
      subtitle: 'Backup and restore your data',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
        );
      },
    );
  }

  Widget _buildExportSettings() {
    return _buildSettingsTile(
      icon: Icons.file_download_outlined,
      title: 'Export Data',
      subtitle: 'Export as PDF, Excel, or CSV',
      onTap: _showExportOptions,
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Text(
                'Export Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate a PDF report'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              subtitle: const Text('Generate an Excel spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.blue),
              title: const Text('Export as CSV'),
              subtitle: const Text('Generate a CSV file'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    setState(() => _isLoading = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final currencyProvider = context.read<CurrencyProvider>();

      final transactions = transactionProvider.transactions;
      final categories = {for (var c in categoryProvider.categories) c.id: c};

      final now = DateTime.now();
      final dateRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      );

      await ExportService.exportToPDF(
        transactions: transactions,
        categories: categories,
        currencySymbol: currencyProvider.currencySymbol,
        dateRange: dateRange,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported to PDF successfully'),
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

    setState(() => _isLoading = false);
  }

  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final currencyProvider = context.read<CurrencyProvider>();

      final transactions = transactionProvider.transactions;
      final categories = {for (var c in categoryProvider.categories) c.id: c};

      await ExportService.exportToExcel(
        transactions: transactions,
        categories: categories,
        currencySymbol: currencyProvider.currencySymbol,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported to Excel successfully'),
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

    setState(() => _isLoading = false);
  }

  Future<void> _exportToCSV() async {
    setState(() => _isLoading = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      final transactions = transactionProvider.transactions;
      final categories = {for (var c in categoryProvider.categories) c.id: c};

      await ExportService.exportToCSV(
        transactions: transactions,
        categories: categories,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported to CSV successfully'),
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

    setState(() => _isLoading = false);
  }

  Widget _buildBiometricSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSwitchTile(
          icon: Icons.fingerprint,
          title: 'Biometric Lock',
          subtitle: 'Use fingerprint or face ID',
          value: settings.biometricEnabled,
          onChanged: (value) async {
            await settings.setBiometricEnabled(value);
          },
        );
      },
    );
  }

  Widget _buildPinSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSettingsTile(
          icon: Icons.lock_outline,
          title: settings.hasPin ? 'Change PIN' : 'Set PIN',
          subtitle: settings.hasPin ? 'PIN is set' : 'Create a 4-digit PIN',
          onTap: () => _showPinDialog(settings),
        );
      },
    );
  }

  void _showPinDialog(SettingsProvider settings) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final currentPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(settings.hasPin ? 'Change PIN' : 'Set PIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (settings.hasPin) ...[
                TextField(
                  controller: currentPinController,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: AppSizes.md),
              ],
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'Enter 4-digit PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (settings.hasPin)
            TextButton(
              onPressed: () async {
                // Verify current PIN before removing
                if (!settings.verifyPin(currentPinController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Current PIN is incorrect'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                await settings.removePin();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN removed'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Remove PIN'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (settings.hasPin &&
                  !settings.verifyPin(currentPinController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current PIN is incorrect'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits')),
                );
                return;
              }

              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }

              await settings.setPin(pinController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN set successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildShowBalanceSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSwitchTile(
          icon: Icons.visibility_outlined,
          title: 'Show Balance',
          subtitle: 'Display balance on home screen',
          value: settings.showBalance,
          onChanged: (value) async {
            await settings.setShowBalance(value);
          },
        );
      },
    );
  }

  Widget _buildNotificationSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Push Notifications',
          subtitle: 'Receive notifications',
          value: settings.notificationsEnabled,
          onChanged: (value) async {
            await settings.setNotificationsEnabled(value);
          },
        );
      },
    );
  }

  Widget _buildBudgetAlertSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSwitchTile(
          icon: Icons.warning_amber_outlined,
          title: 'Budget Alerts',
          subtitle: 'Get notified when exceeding budgets',
          value: settings.budgetAlertsEnabled,
          onChanged: (value) async {
            await settings.setBudgetAlertsEnabled(value);
          },
        );
      },
    );
  }

  Widget _buildDailyReminderSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSwitchTile(
              icon: Icons.access_time,
              title: 'Daily Reminder',
              subtitle: 'Remind to log expenses',
              value: settings.dailyReminderEnabled,
              onChanged: (value) async {
                await settings.setDailyReminderEnabled(value);
              },
            ),
            if (settings.dailyReminderEnabled)
              _buildSettingsTile(
                icon: Icons.schedule,
                title: 'Reminder Time',
                subtitle: settings.dailyReminderTime,
                onTap: () => _showTimePicker(settings),
              ),
          ],
        );
      },
    );
  }

  void _showTimePicker(SettingsProvider settings) async {
    final parts = settings.dailyReminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      final formatted =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await settings.setDailyReminderTime(formatted);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${time.format(context)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _rateApp() {
    // TODO: Implement app store rating
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening app store...')));
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out Expense Tracker - The best app to manage your finances!\n\n'
            'Download now: [App Store Link]',
        subject: 'Expense Tracker App',
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This app stores all your financial '
            'data locally on your device. We do not collect, transmit, or share '
            'any of your personal or financial information.\n\n'
            'All data remains on your device and is encrypted for your security.\n\n'
            'If you choose to backup your data, it will be stored in your chosen '
            'location (local storage or cloud service) under your control.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Expense Tracker, you agree to:\n\n'
            '1. Use the app for personal financial tracking only\n'
            '2. Not attempt to reverse engineer or modify the app\n'
            '3. Keep your data secure and backed up\n'
            '4. Not hold the developers liable for any financial decisions\n\n'
            'This app is provided as-is for personal use. We are not responsible '
            'for any financial losses or damages resulting from the use of this app.\n\n'
            'For support, please contact: support@expensetracker.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteAllData() async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete All Data',
      message:
          'Are you sure you want to delete ALL your data?\n\n'
          'This will permanently delete:\n'
          '• All transactions\n'
          '• All accounts\n'
          '• All budgets\n'
          '• All categories\n'
          '• All settings\n\n'
          'THIS ACTION CANNOT BE UNDONE!',
      confirmText: 'Delete Everything',
      isDangerous: true,
      icon: Icons.warning_rounded,
    );

    if (confirm == true) {
      if (mounted) {
        final doubleConfirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Final Confirmation'),
            content: const Text(
              'This is your last chance!\n\n'
              'Type "DELETE" to confirm permanent deletion of all data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final controller = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Type DELETE'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'DELETE'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.text == 'DELETE') {
                              Navigator.pop(context);
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please type DELETE correctly'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('I Understand'),
              ),
            ],
          ),
        );

        if (doubleConfirm == true) {
          setState(() => _isLoading = true);

          try {
            if (mounted) {
              final transactionProvider = context.read<TransactionProvider>();
              final budgetProvider = context.read<BudgetProvider>();
              final accountProvider = context.read<AccountProvider>();

              final transactionIds = transactionProvider.allTransactions
                  .map((t) => t.id)
                  .toList();

              if (transactionIds.isNotEmpty) {
                await transactionProvider.deleteMultipleTransactions(
                  transactionIds,
                );
              }

              final budgetFutures = budgetProvider.budgets
                  .map((b) => budgetProvider.deleteBudget(b.id))
                  .toList();

              if (budgetFutures.isNotEmpty) {
                await Future.wait(budgetFutures);
              }

              final accountFutures = accountProvider.accounts
                  .map((a) => accountProvider.deleteAccount(a.id))
                  .toList();

              if (accountFutures.isNotEmpty) {
                await Future.wait(accountFutures);
              }

              if (mounted) {
                await Future.wait([
                  transactionProvider.loadTransactions(),
                  accountProvider.loadAccounts(),
                  budgetProvider.loadBudgets(),
                  context.read<CategoryProvider>().loadCategories(),
                ]);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting data: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }

          setState(() => _isLoading = false);
        }
      }
    }
  }
}
