class Tables {
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String accounts = 'accounts';
  static const String budgets = 'budgets';
  static const String users = 'users';
  static const String recurringTransactions = 'recurring_transactions';
  static const String attachments = 'attachments';
  static const String tags = 'tags';
  static const String transactionTags = 'transaction_tags';

  static const String transactionId = 'id';
  static const String transactionTitle = 'title';
  static const String transactionAmount = 'amount';
  static const String transactionType = 'type';
  static const String transactionCategoryId = 'categoryId';
  static const String transactionAccountId = 'accountId';
  static const String transactionToAccountId = 'toAccountId';
  static const String transactionDate = 'date';
  static const String transactionNote = 'note';
  static const String transactionReceiptImage = 'receiptImage';
  static const String transactionIsRecurring = 'isRecurring';
  static const String transactionRecurringId = 'recurringId';
  static const String transactionCreatedAt = 'createdAt';
  static const String transactionUpdatedAt = 'updatedAt';

  static const String categoryId = 'id';
  static const String categoryName = 'name';
  static const String categoryIconCodePoint = 'iconCodePoint';
  static const String categoryIconFontFamily = 'iconFontFamily';
  static const String categoryColor = 'color';
  static const String categoryIsIncome = 'isIncome';
  static const String categoryIsDefault = 'isDefault';
  static const String categorySortOrder = 'sortOrder';
  static const String categoryCreatedAt = 'createdAt';

  static const String accountId = 'id';
  static const String accountName = 'name';
  static const String accountType = 'type';
  static const String accountBalance = 'balance';
  static const String accountInitialBalance = 'initialBalance';
  static const String accountIconCodePoint = 'iconCodePoint';
  static const String accountIconFontFamily = 'iconFontFamily';
  static const String accountColor = 'color';
  static const String accountCurrency = 'currency';
  static const String accountIncludeInTotal = 'includeInTotal';
  static const String accountIsDefault = 'isDefault';
  static const String accountCreatedAt = 'createdAt';
  static const String accountUpdatedAt = 'updatedAt';

  static const String budgetId = 'id';
  static const String budgetName = 'name';
  static const String budgetAmount = 'amount';
  static const String budgetSpent = 'spent';
  static const String budgetCategoryId = 'categoryId';
  static const String budgetPeriod = 'period';
  static const String budgetStartDate = 'startDate';
  static const String budgetEndDate = 'endDate';
  static const String budgetIsActive = 'isActive';
  static const String budgetNotifyOnExceed = 'notifyOnExceed';
  static const String budgetNotifyAtPercent = 'notifyAtPercent';
  static const String budgetCreatedAt = 'createdAt';
  static const String budgetUpdatedAt = 'updatedAt';

  static const String userId = 'id';
  static const String userName = 'name';
  static const String userEmail = 'email';
  static const String userAvatar = 'avatar';
  static const String userCurrency = 'currency';
  static const String userCurrencySymbol = 'currencySymbol';
  static const String userLocale = 'locale';
  static const String userThemeMode = 'themeMode';
  static const String userPinHash = 'pinHash';
  static const String userBiometricEnabled = 'biometricEnabled';
  static const String userCreatedAt = 'createdAt';
  static const String userUpdatedAt = 'updatedAt';

  static String get createTransactionsTable =>
      '''
    CREATE TABLE $transactions (
      $transactionId TEXT PRIMARY KEY,
      $transactionTitle TEXT NOT NULL,
      $transactionAmount REAL NOT NULL,
      $transactionType INTEGER NOT NULL,
      $transactionCategoryId TEXT NOT NULL,
      $transactionAccountId TEXT NOT NULL,
      $transactionToAccountId TEXT,
      $transactionDate TEXT NOT NULL,
      $transactionNote TEXT,
      $transactionReceiptImage TEXT,
      $transactionIsRecurring INTEGER DEFAULT 0,
      $transactionRecurringId TEXT,
      $transactionCreatedAt TEXT NOT NULL,
      $transactionUpdatedAt TEXT NOT NULL
    )
  ''';

  static String get createCategoriesTable =>
      '''
    CREATE TABLE $categories (
      $categoryId TEXT PRIMARY KEY,
      $categoryName TEXT NOT NULL,
      $categoryIconCodePoint INTEGER NOT NULL,
      $categoryIconFontFamily TEXT,
      $categoryColor INTEGER NOT NULL,
      $categoryIsIncome INTEGER NOT NULL,
      $categoryIsDefault INTEGER DEFAULT 0,
      $categorySortOrder INTEGER DEFAULT 0,
      $categoryCreatedAt TEXT NOT NULL
    )
  ''';

  static String get createAccountsTable =>
      '''
    CREATE TABLE $accounts (
      $accountId TEXT PRIMARY KEY,
      $accountName TEXT NOT NULL,
      $accountType INTEGER NOT NULL,
      $accountBalance REAL NOT NULL,
      $accountInitialBalance REAL NOT NULL,
      $accountIconCodePoint INTEGER NOT NULL,
      $accountIconFontFamily TEXT,
      $accountColor INTEGER NOT NULL,
      $accountCurrency TEXT NOT NULL,
      $accountIncludeInTotal INTEGER DEFAULT 1,
      $accountIsDefault INTEGER DEFAULT 0,
      $accountCreatedAt TEXT NOT NULL,
      $accountUpdatedAt TEXT NOT NULL
    )
  ''';

  static String get createBudgetsTable =>
      '''
    CREATE TABLE $budgets (
      $budgetId TEXT PRIMARY KEY,
      $budgetName TEXT NOT NULL,
      $budgetAmount REAL NOT NULL,
      $budgetSpent REAL DEFAULT 0,
      $budgetCategoryId TEXT NOT NULL,
      $budgetPeriod INTEGER NOT NULL,
      $budgetStartDate TEXT NOT NULL,
      $budgetEndDate TEXT NOT NULL,
      $budgetIsActive INTEGER DEFAULT 1,
      $budgetNotifyOnExceed INTEGER DEFAULT 1,
      $budgetNotifyAtPercent INTEGER DEFAULT 80,
      $budgetCreatedAt TEXT NOT NULL,
      $budgetUpdatedAt TEXT NOT NULL
    )
  ''';

  static String get createUsersTable =>
      '''
    CREATE TABLE $users (
      $userId TEXT PRIMARY KEY,
      $userName TEXT,
      $userEmail TEXT,
      $userAvatar TEXT,
      $userCurrency TEXT DEFAULT 'USD',
      $userCurrencySymbol TEXT DEFAULT '\$',
      $userLocale TEXT DEFAULT 'en_US',
      $userThemeMode INTEGER DEFAULT 0,
      $userPinHash TEXT,
      $userBiometricEnabled INTEGER DEFAULT 0,
      $userCreatedAt TEXT NOT NULL,
      $userUpdatedAt TEXT NOT NULL
    )
  ''';

  static List<String> get createIndexes => [
    'CREATE INDEX idx_transactions_date ON $transactions($transactionDate)',
    'CREATE INDEX idx_transactions_category ON $transactions($transactionCategoryId)',
    'CREATE INDEX idx_transactions_account ON $transactions($transactionAccountId)',
    'CREATE INDEX idx_transactions_type ON $transactions($transactionType)',
    'CREATE INDEX idx_categories_type ON $categories($categoryIsIncome)',
    'CREATE INDEX idx_budgets_category ON $budgets($budgetCategoryId)',
    'CREATE INDEX idx_budgets_active ON $budgets($budgetIsActive)',
  ];
}
