import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/dialogs/account_picker_dialog.dart';
import '../../widgets/dialogs/category_picker_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.initialType, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  int _selectedTabIndex = 1;
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _selectedToAccount;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _receiptImage;
  bool _isLoading = false;

  TransactionModel? _originalTransaction;

  bool get _isEditing => widget.transaction != null;

  TransactionType get _selectedType =>
      TransactionType.values[_selectedTabIndex];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    debugPrint('initialType received: ${widget.initialType}');
    debugPrint('initialType index: ${widget.initialType?.index}');
    if (_isEditing) {
      _selectedTabIndex = widget.transaction!.type.index;
      _originalTransaction = widget.transaction;
      _populateFields();
    } else if (widget.initialType != null) {
      _selectedTabIndex = widget.initialType!.index;
    } else {
      _selectedTabIndex = 1;
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );

    _tabController!.addListener(_handleTabChange);

    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setDefaultAccount();
      });
    }
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging) return;

    setState(() {
      _selectedTabIndex = _tabController!.index;
      if (_selectedType != TransactionType.transfer) {
        _selectedCategory = null;
      }
    });
  }

  void _setDefaultAccount() {
    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isNotEmpty && _selectedAccount == null) {
      setState(() {
        _selectedAccount = accounts.firstWhere(
          (a) => a.isDefault,
          orElse: () => accounts.first,
        );
      });
    }
  }

  void _populateFields() {
    final t = widget.transaction!;
    _amountController.text = t.amount.toStringAsFixed(2);
    _titleController.text = t.title;
    _noteController.text = t.note ?? '';
    _selectedDate = t.date;
    _selectedTime = TimeOfDay.fromDateTime(t.date);
    _receiptImage = t.receiptImage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final categories = context.read<CategoryProvider>().categories;
      final accounts = context.read<AccountProvider>().accounts;

      setState(() {
        try {
          _selectedCategory = categories.firstWhere(
            (c) => c.id == t.categoryId,
          );
        } catch (_) {
          _selectedCategory = null;
        }

        try {
          _selectedAccount = accounts.firstWhere((a) => a.id == t.accountId);
        } catch (_) {
          _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
        }

        if (t.toAccountId != null) {
          try {
            _selectedToAccount = accounts.firstWhere(
              (a) => a.id == t.toAccountId,
            );
          } catch (_) {
            _selectedToAccount = null;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _typeColor {
    switch (_selectedType) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  String get _typeLabel {
    switch (_selectedType) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteTransaction,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeSelector(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountField(currencyProvider),
                    const SizedBox(height: AppSizes.lg),

                    CustomTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Enter transaction title',
                      prefixIcon: Icons.title,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    if (_selectedType != TransactionType.transfer) ...[
                      _buildCategorySelector(),
                      const SizedBox(height: AppSizes.md),
                    ],

                    _buildAccountSelector(
                      label: _selectedType == TransactionType.transfer
                          ? 'From Account'
                          : 'Account',
                      selectedAccount: _selectedAccount,
                      onSelect: (account) {
                        setState(() => _selectedAccount = account);
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    if (_selectedType == TransactionType.transfer) ...[
                      _buildAccountSelector(
                        label: 'To Account',
                        selectedAccount: _selectedToAccount,
                        excludeAccount: _selectedAccount,
                        onSelect: (account) {
                          setState(() => _selectedToAccount = account);
                        },
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],

                    Row(
                      children: [
                        Expanded(child: _buildDateSelector()),
                        const SizedBox(width: AppSizes.md),
                        Expanded(child: _buildTimeSelector()),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),

                    CustomTextField(
                      controller: _noteController,
                      label: 'Note (Optional)',
                      hint: 'Add a note',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSizes.md),

                    _buildReceiptSection(),
                    const SizedBox(height: AppSizes.xl),

                    _buildSaveButton(),

                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2D2D44)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          color: _typeColor,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(AppSizes.radiusMd),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          _buildTab(
            icon: Icons.arrow_downward_rounded,
            label: 'Income',
            isSelected: _selectedTabIndex == 0,
            color: AppColors.income,
          ),
          _buildTab(
            icon: Icons.arrow_upward_rounded,
            label: 'Expense',
            isSelected: _selectedTabIndex == 1,
            color: AppColors.expense,
          ),
          _buildTab(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            isSelected: _selectedTabIndex == 2,
            color: AppColors.transfer,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
  }) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildAmountField(CurrencyProvider currencyProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _typeColor.withValues(alpha: 0.15),
            _typeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$_typeLabel Amount',
            style: TextStyle(
              color: _typeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  currencyProvider.currencySymbol,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: _typeColor,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: _typeColor.withValues(alpha: 0.3),
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                    errorStyle: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        InkWell(
          onTap: _showCategoryPicker,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedCategory != null
                    ? Colors.grey.shade300
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        _selectedCategory?.color.withValues(alpha: 0.2) ??
                        Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    _selectedCategory?.icon ?? Icons.category_outlined,
                    color: _selectedCategory?.color ?? Colors.grey,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    _selectedCategory?.name ?? 'Select Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: _selectedCategory != null
                          ? null
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector({
    required String label,
    required AccountModel? selectedAccount,
    AccountModel? excludeAccount,
    required Function(AccountModel) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        InkWell(
          onTap: () => _showAccountPicker(
            selectedAccount: selectedAccount,
            excludeAccount: excludeAccount,
            onSelect: onSelect,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        selectedAccount?.color.withValues(alpha: 0.2) ??
                        Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    selectedAccount?.icon ??
                        Icons.account_balance_wallet_outlined,
                    color: selectedAccount?.color ?? Colors.grey,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAccount?.name ?? 'Select Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: selectedAccount != null
                              ? null
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (selectedAccount != null) ...[
                        const SizedBox(height: 2),
                        Consumer<CurrencyProvider>(
                          builder: (context, currency, _) => Text(
                            currency.formatAmount(selectedAccount.balance),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: _typeColor, size: 18),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.access_time, color: _typeColor, size: 18),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipt (Optional)',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: AppSizes.sm),
        if (_receiptImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Image.file(
                  File(_receiptImage!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _receiptImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                color: Colors.grey.shade50,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey.shade400,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add receipt',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _typeColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _typeColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isEditing ? Icons.check : Icons.add, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Update Transaction' : 'Save Transaction',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _typeColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _typeColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: CategoryPickerDialog(
          isIncome: _selectedType == TransactionType.income,
          selectedCategory: _selectedCategory,
          onSelect: (category) {
            setState(() => _selectedCategory = category);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showAccountPicker({
    required AccountModel? selectedAccount,
    AccountModel? excludeAccount,
    required Function(AccountModel) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AccountPickerDialog(
          selectedAccount: selectedAccount,
          excludeAccount: excludeAccount,
          onSelect: (account) {
            onSelect(account);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Receipt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Use camera to capture'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select existing image'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );

    if (source != null) {
      try {
        final picked = await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1200,
        );
        if (picked != null) {
          setState(() => _receiptImage = picked.path);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType != TransactionType.transfer &&
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an account'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer) {
      if (_selectedToAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select destination account'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      if (_selectedAccount!.id == _selectedToAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot transfer to the same account'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final amount = double.parse(_amountController.text);

      final transaction = TransactionModel(
        id: widget.transaction?.id ?? '',
        title: _titleController.text.trim(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategory?.id ?? 'transfer',
        accountId: _selectedAccount!.id,
        toAccountId: _selectedToAccount?.id,
        date: dateTime,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        receiptImage: _receiptImage,
      );

      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();
      final budgetProvider = context.read<BudgetProvider>();

      bool success;

      if (_isEditing && _originalTransaction != null) {
        await _revertAccountBalance(accountProvider, _originalTransaction!);

        if (_originalTransaction!.type == TransactionType.expense) {
          await budgetProvider.updateBudgetSpent(
            _originalTransaction!.categoryId,
            _originalTransaction!.amount,
            subtract: true,
          );
        }

        success = await transactionProvider.updateTransaction(transaction);
      } else {
        success = await transactionProvider.addTransaction(transaction);
      }

      if (success) {
        await _applyAccountBalance(accountProvider, transaction);

        if (transaction.type == TransactionType.expense) {
          await budgetProvider.updateBudgetSpent(
            transaction.categoryId,
            transaction.amount,
          );
        }

        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Transaction updated!' : 'Transaction added!',
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyAccountBalance(
    AccountProvider accountProvider,
    TransactionModel transaction,
  ) async {
    switch (transaction.type) {
      case TransactionType.income:
        await accountProvider.updateBalance(
          transaction.accountId,
          transaction.amount,
        );
        break;
      case TransactionType.expense:
        await accountProvider.updateBalance(
          transaction.accountId,
          -transaction.amount,
        );
        break;
      case TransactionType.transfer:
        await accountProvider.updateBalance(
          transaction.accountId,
          -transaction.amount,
        );
        if (transaction.toAccountId != null) {
          await accountProvider.updateBalance(
            transaction.toAccountId!,
            transaction.amount,
          );
        }
        break;
    }
  }

  Future<void> _revertAccountBalance(
    AccountProvider accountProvider,
    TransactionModel transaction,
  ) async {
    switch (transaction.type) {
      case TransactionType.income:
        await accountProvider.updateBalance(
          transaction.accountId,
          -transaction.amount,
        );
        break;
      case TransactionType.expense:
        await accountProvider.updateBalance(
          transaction.accountId,
          transaction.amount,
        );
        break;
      case TransactionType.transfer:
        await accountProvider.updateBalance(
          transaction.accountId,
          transaction.amount,
        );
        if (transaction.toAccountId != null) {
          await accountProvider.updateBalance(
            transaction.toAccountId!,
            -transaction.amount,
          );
        }
        break;
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Delete Transaction'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this transaction? This will also revert the account balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final accountProvider = context.read<AccountProvider>();
      final budgetProvider = context.read<BudgetProvider>();

      await _revertAccountBalance(accountProvider, widget.transaction!);

      if (widget.transaction!.type == TransactionType.expense) {
        await budgetProvider.updateBudgetSpent(
          widget.transaction!.categoryId,
          widget.transaction!.amount,
          subtract: true,
        );
      }

      if (mounted) {
        await context.read<TransactionProvider>().deleteTransaction(
          widget.transaction!.id,
        );
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Transaction deleted'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
