import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/backup_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/dialogs/confirm_dialog.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _backupService = BackupService();
  bool _isLoading = false;
  List<BackupInfo> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    _backups = await _backupService.listBackups();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _loadBackups,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              _buildBackupSection(),
              const SizedBox(height: AppSizes.xl),

              _buildRestoreSection(),
              const SizedBox(height: AppSizes.xl),

              _buildAutoBackupSection(),
              const SizedBox(height: AppSizes.xl),

              _buildBackupHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Backup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Save your data to a file',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Creates a backup file containing all your transactions, accounts, budgets, and categories.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createLocalBackup,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save Locally'),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareBackup,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_download,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restore Backup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Import data from backup file',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Replace all current data with data from a backup file. This action cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton.icon(
              onPressed: _restoreFromFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Backup File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.sm),
                SwitchListTile(
                  title: const Text('Enable Auto Backup'),
                  subtitle: const Text(
                    'Backup automatically when app opens (once daily)',
                  ),
                  value: settings.autoBackupEnabled,
                  onChanged: (value) async {
                    await settings.setAutoBackupEnabled(value);
                    // Trigger immediate check if enabled
                    if (value) {
                      _backupService.performAutoBackupIfNeeded(
                        true,
                        settings.autoBackupRetention,
                      );
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (settings.autoBackupEnabled) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Retention Policy',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      const Text('Keep last'),
                      Expanded(
                        child: Slider(
                          value: settings.autoBackupRetention.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${settings.autoBackupRetention} backups',
                          onChanged: (value) {
                            settings.setAutoBackupRetention(value.toInt());
                          },
                        ),
                      ),
                      Text('${settings.autoBackupRetention} backups'),
                    ],
                  ),
                  Text(
                    'Older backups will be automatically deleted to save space.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackupHistory() {
    if (_backups.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.backup_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'No backup history',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backup History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.md),
        ..._backups.map((backup) => _buildBackupItem(backup)),
      ],
    );
  }

  Widget _buildBackupItem(BackupInfo backup) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.backup, color: AppColors.primary),
        ),
        title: Text(
          backup.fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(backup.modifiedAt),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${backup.formattedSize} • ${backup.validation.totalItems} items',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreBackup(backup);
                break;
              case 'share':
                _shareBackupFile(File(backup.path));
                break;
              case 'delete':
                _deleteBackup(backup);
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 12),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createLocalBackup() async {
    setState(() => _isLoading = true);

    try {
      final file = await _backupService.exportBackup();
      await _loadBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to ${file.path}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _shareBackup() async {
    setState(() => _isLoading = true);

    try {
      await _backupService.shareBackup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _shareBackupFile(File file) async {
    setState(() => _isLoading = true);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Expense Tracker Backup',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _restoreFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final validation = await _backupService.validateBackup(file);

    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.error ?? 'Invalid backup file'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      _showRestoreConfirmation(file, validation);
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final file = File(backup.path);
    _showRestoreConfirmation(file, backup.validation);
  }

  void _showRestoreConfirmation(
    File file,
    BackupValidationResult validation,
  ) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Restore Backup',
      message:
          'This will replace all your current data with:\n\n'
          '• ${validation.transactionCount} transactions\n'
          '• ${validation.accountCount} accounts\n'
          '• ${validation.budgetCount} budgets\n'
          '• ${validation.categoryCount} categories\n\n'
          'This action cannot be undone.',
      confirmText: 'Restore',
      isDangerous: true,
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success = await _backupService.importBackup(file);

      if (success && mounted) {
        await Future.wait([
          context.read<TransactionProvider>().loadTransactions(),
          context.read<AccountProvider>().loadAccounts(),
          context.read<CategoryProvider>().loadCategories(),
          context.read<BudgetProvider>().loadBudgets(),
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup restored successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore backup'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete Backup',
      message: 'Are you sure you want to delete this backup file?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirm == true) {
      final success = await _backupService.deleteBackup(backup.path);

      if (success) {
        await _loadBackups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }
}
