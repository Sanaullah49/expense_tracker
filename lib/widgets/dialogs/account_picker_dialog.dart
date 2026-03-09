import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/currency_provider.dart';

class AccountPickerDialog extends StatelessWidget {
  final AccountModel? selectedAccount;
  final AccountModel? excludeAccount;
  final Function(AccountModel) onSelect;

  const AccountPickerDialog({
    super.key,
    this.selectedAccount,
    this.excludeAccount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, CurrencyProvider>(
      builder: (context, accountProvider, currencyProvider, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final accounts = accountProvider.accounts
            .where((a) => a.id != excludeAccount?.id)
            .toList();

        return Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Account',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.addAccount);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              Expanded(
                child: accounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No accounts',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.addAccount,
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Account'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final isSelected = selectedAccount?.id == account.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.xs),
                            child: ListTile(
                              onTap: () => onSelect(account),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: account.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
                                ),
                                child: Icon(account.icon, color: account.color),
                              ),
                              title: Text(
                                account.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                currencyProvider.formatAmount(account.balance),
                                style: TextStyle(
                                  color: account.balance >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: account.color,
                                    )
                                  : null,
                              selected: isSelected,
                              selectedTileColor: account.color.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
