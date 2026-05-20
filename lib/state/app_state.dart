import 'package:flutter/material.dart';
import '../models.dart';
import '../services/price_service.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../services/update_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final PriceService _priceService = PriceService();
  final CurrencyService _currencyService = CurrencyService();

  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<InvestmentAsset> _assets = [];
  List<InvestmentTransaction> _investmentTransactions = [];
  double _cashReserves = 50000.0;
  String _locale = 'en';
  bool _remindersEnabled = true;
  int _reminderHour = 20; // 8:00 PM
  int _reminderMinute = 0;

  // New Phase 2 Expansion Properties
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'VND': 25400.0,
    'EUR': 0.92,
    'JPY': 156.0,
    'GBP': 0.79,
    'SGD': 1.34
  };
  List<AppCategory> _categories = [];
  ThemeMode _themeMode = ThemeMode.dark;
  String _themeName = 'dark'; // 'dark' (Slate), 'light' (Cream), 'gold' (Luxurious Gold)

  // New Phase 3 Properties
  bool _adsEnabled = true;
  bool _isGoldThemeUnlocked = false;
  String _currentVersion = '1.0.0+1';
  String _latestVersion = '1.0.0+1';
  bool _updateAvailable = false;
  String _updateReleaseNotes = '';
  bool _isDownloadingUpdate = false;
  double _downloadProgress = 0.0;
  bool _updateSuccess = false;

  bool _isLoading = false;
  bool _isLivePrices = true; // Tracks if last price refresh was from Yahoo API

  // Getters
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<InvestmentAsset> get assets => _assets;
  List<InvestmentTransaction> get investmentTransactions => _investmentTransactions;
  double get cashReserves => _cashReserves;
  String get locale => _locale;
  bool get remindersEnabled => _remindersEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get isLoading => _isLoading;
  bool get isLivePrices => _isLivePrices;

  // New Phase 2 Getters
  String get selectedCurrency => _selectedCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  List<AppCategory> get categories => _categories;
  ThemeMode get themeMode => _themeMode;

  // New Phase 3 Getters
  String get themeName => _themeName;
  bool get adsEnabled => _adsEnabled;
  bool get isGoldThemeUnlocked => _isGoldThemeUnlocked;
  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  bool get updateAvailable => _updateAvailable;
  String get updateReleaseNotes => _updateReleaseNotes;
  bool get isDownloadingUpdate => _isDownloadingUpdate;
  double get downloadProgress => _downloadProgress;
  bool get updateSuccess => _updateSuccess;

  // Analytical getters
  double get totalPortfolioValue => _assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
  double get netWorth => _cashReserves + totalPortfolioValue;

  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.income && t.dateTime.month == now.month && t.dateTime.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.expense && t.dateTime.month == now.month && t.dateTime.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Initialize notification service
    await NotificationService().init();

    final data = await _storageService.loadData();
    if (data != null) {
      _transactions = data.transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      _budgets = data.budgetsJson.map((json) => Budget.fromJson(json)).toList();
      _assets = data.assetsJson.map((json) => InvestmentAsset.fromJson(json)).toList();
      _investmentTransactions = data.investTransactionsJson.map((json) => InvestmentTransaction.fromJson(json)).toList();
      _cashReserves = data.cashReserves;
      _locale = data.locale;
      _remindersEnabled = data.remindersEnabled;
      _reminderHour = data.reminderHour;
      _reminderMinute = data.reminderMinute;

      // Parse expansion fields
      _selectedCurrency = data.selectedCurrency;
      if (data.exchangeRates.isNotEmpty) {
        _exchangeRates = data.exchangeRates;
      }
      _categories = data.categoriesJson.map((json) => AppCategory.fromJson(json)).toList();
      if (_categories.isEmpty) {
        _populateDefaultCategories();
      }
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == data.themeMode,
        orElse: () => ThemeMode.dark,
      );
      // Determine theme name from saved themeMode representation or direct themeName
      if (data.currentVersion == '1.1.0' || data.isGoldThemeUnlocked) {
        _isGoldThemeUnlocked = true;
      }
      _themeName = data.themeMode.contains('ThemeMode.dark')
          ? 'dark'
          : data.themeMode.contains('ThemeMode.light')
              ? 'light'
              : data.currentVersion == '1.1.0' && data.themeMode.contains('gold')
                  ? 'gold'
                  : data.themeMode.replaceAll('ThemeMode.', ''); // handles direct string keys like 'gold', 'light', etc.
      
      _adsEnabled = data.adsEnabled;
      _currentVersion = data.currentVersion;

      // Recalculate budget spent amounts just to be 100% correct
      _recalculateBudgetSpent();
    } else {
      _populateDefaultData();
    }

    _isLoading = false;
    notifyListeners();

    // Trigger an initial price fetch and exchange rate update asynchronously
    refreshPrices();
    refreshExchangeRates();
    updateNotificationSchedule();
  }

  void _populateDefaultCategories() {
    _categories = [
      AppCategory(id: 'c1', name: 'Food & Drinks', icon: 'restaurant', colorValue: 0xFFF43F5E, isCustom: false, isIncome: false),
      AppCategory(id: 'c2', name: 'Transportation', icon: 'directions_car', colorValue: 0xFF8B5CF6, isCustom: false, isIncome: false),
      AppCategory(id: 'c3', name: 'Shopping', icon: 'shopping_bag', colorValue: 0xFFF59E0B, isCustom: false, isIncome: false),
      AppCategory(id: 'c4', name: 'Entertainment', icon: 'sports_esports', colorValue: 0xFF6366F1, isCustom: false, isIncome: false),
      AppCategory(id: 'c5', name: 'Bills & Utilities', icon: 'receipt', colorValue: 0xFF06B6D4, isCustom: false, isIncome: false),
      AppCategory(id: 'c6', name: 'Salary Income', icon: 'payments', colorValue: 0xFF10B981, isCustom: false, isIncome: true),
      AppCategory(id: 'c7', name: 'Invest Dividends', icon: 'trending_up', colorValue: 0xFF10B981, isCustom: false, isIncome: true),
      AppCategory(id: 'c8', name: 'Other Details', icon: 'more_horiz', colorValue: 0xFF94A3B8, isCustom: false, isIncome: false),
    ];
  }

  void _populateDefaultData() {
    _locale = 'en';
    _cashReserves = 25000.0;
    _remindersEnabled = true;
    _reminderHour = 20;
    _reminderMinute = 0;
    _selectedCurrency = 'USD';
    _themeMode = ThemeMode.dark;

    _populateDefaultCategories();

    // Default Budgets
    _budgets = [
      Budget(id: 'b1', category: 'Food & Drinks', limitAmount: 500.0),
      Budget(id: 'b2', category: 'Transportation', limitAmount: 150.0),
      Budget(id: 'b3', category: 'Shopping', limitAmount: 400.0),
      Budget(id: 'b4', category: 'Entertainment', limitAmount: 200.0),
      Budget(id: 'b5', category: 'Bills & Utilities', limitAmount: 300.0),
    ];

    // Default Transactions (simulating some activity in the current month)
    final now = DateTime.now();
    _transactions = [
      Transaction(
        id: 't1',
        title: 'Monthly Salary',
        amount: 3200.0,
        type: TransactionType.income,
        category: 'Salary Income',
        dateTime: now.subtract(const Duration(days: 5)),
        notes: 'Tech Corp Direct Deposit',
      ),
      Transaction(
        id: 't2',
        title: 'Weekly Grocery Shopping',
        amount: 142.50,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        dateTime: now.subtract(const Duration(days: 3)),
        notes: 'Organic grocery mart',
      ),
      Transaction(
        id: 't3',
        title: 'Subway Ride Ticket',
        amount: 12.0,
        type: TransactionType.expense,
        category: 'Transportation',
        dateTime: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 't4',
        title: 'Premium Leather Shoes',
        amount: 180.0,
        type: TransactionType.expense,
        category: 'Shopping',
        dateTime: now.subtract(const Duration(days: 1)),
        notes: 'Classic leather boots',
      ),
      Transaction(
        id: 't5',
        title: 'Cyberpunk Cinema Night',
        amount: 45.0,
        type: TransactionType.expense,
        category: 'Entertainment',
        dateTime: now,
        notes: 'IMAX Ticket + popcorn combo',
      ),
      Transaction(
        id: 't6',
        title: 'High-speed Fiber Internet',
        amount: 75.0,
        type: TransactionType.expense,
        category: 'Bills & Utilities',
        dateTime: now.subtract(const Duration(days: 4)),
      ),
    ];

    // Default Investment Assets (Stocks, Crypto, Precious Metals)
    _assets = [
      // Stocks
      InvestmentAsset(
        id: 'a1',
        name: 'Apple Inc.',
        ticker: 'AAPL',
        category: AssetCategory.stock,
        currentPrice: 185.20,
        changePercent: 1.25,
        historicalPrices: [180.0, 181.5, 183.0, 182.20, 184.10, 183.90, 185.20],
        averageBuyPrice: 182.0,
        totalQuantity: 15.0, // Owned asset
      ),
      InvestmentAsset(
        id: 'a2',
        name: 'Tesla Inc.',
        ticker: 'TSLA',
        category: AssetCategory.stock,
        currentPrice: 175.40,
        changePercent: -2.10,
        historicalPrices: [185.0, 182.0, 180.5, 178.90, 176.40, 177.20, 175.40],
        averageBuyPrice: 0.0,
        totalQuantity: 0.0,
      ),
      InvestmentAsset(
        id: 'a3',
        name: 'Alphabet Inc.',
        ticker: 'GOOG',
        category: AssetCategory.stock,
        currentPrice: 168.30,
        changePercent: 0.85,
        historicalPrices: [165.0, 166.20, 165.90, 167.10, 166.80, 167.90, 168.30],
        averageBuyPrice: 165.0,
        totalQuantity: 10.0, // Owned asset
      ),
      // Crypto
      InvestmentAsset(
        id: 'a4',
        name: 'Bitcoin',
        ticker: 'BTC-USD',
        category: AssetCategory.crypto,
        currentPrice: 65200.0,
        changePercent: 3.45,
        historicalPrices: [62100.0, 63400.0, 62900.0, 64200.0, 63800.0, 64900.0, 65200.0],
        averageBuyPrice: 63000.0,
        totalQuantity: 0.25, // Owned asset
      ),
      InvestmentAsset(
        id: 'a5',
        name: 'Ethereum',
        ticker: 'ETH-USD',
        category: AssetCategory.crypto,
        currentPrice: 3450.0,
        changePercent: -0.95,
        historicalPrices: [3520.0, 3490.0, 3510.0, 3460.0, 3480.0, 3430.0, 3450.0],
        averageBuyPrice: 0.0,
        totalQuantity: 0.0,
      ),
      // Metals
      InvestmentAsset(
        id: 'a6',
        name: 'Gold Futures',
        ticker: 'GC=F',
        category: AssetCategory.metal,
        currentPrice: 2350.0,
        changePercent: 0.45,
        historicalPrices: [2320.0, 2335.0, 2328.0, 2342.0, 2338.0, 2345.0, 2350.0],
        averageBuyPrice: 2310.0,
        totalQuantity: 2.0, // Owned asset (2 ounces)
      ),
      InvestmentAsset(
        id: 'a7',
        name: 'Silver Futures',
        ticker: 'SI=F',
        category: AssetCategory.metal,
        currentPrice: 28.50,
        changePercent: 1.65,
        historicalPrices: [27.20, 27.80, 27.50, 28.10, 28.00, 28.30, 28.50],
        averageBuyPrice: 0.0,
        totalQuantity: 0.0,
      ),
    ];

    // Default Investment Transactions
    _investmentTransactions = [
      InvestmentTransaction(
        id: 'it1',
        assetTicker: 'AAPL',
        type: InvestmentType.buy,
        quantity: 15.0,
        pricePerUnit: 182.0,
        dateTime: now.subtract(const Duration(days: 4)),
      ),
      InvestmentTransaction(
        id: 'it2',
        assetTicker: 'GOOG',
        type: InvestmentType.buy,
        quantity: 10.0,
        pricePerUnit: 165.0,
        dateTime: now.subtract(const Duration(days: 3)),
      ),
      InvestmentTransaction(
        id: 'it3',
        assetTicker: 'BTC-USD',
        type: InvestmentType.buy,
        quantity: 0.25,
        pricePerUnit: 63000.0,
        dateTime: now.subtract(const Duration(days: 2)),
      ),
      InvestmentTransaction(
        id: 'it4',
        assetTicker: 'GC=F',
        type: InvestmentType.buy,
        quantity: 2.0,
        pricePerUnit: 2310.0,
        dateTime: now.subtract(const Duration(days: 1)),
      ),
    ];

    _recalculateBudgetSpent();
    _saveState();
  }

  void _recalculateBudgetSpent() {
    final now = DateTime.now();
    for (var budget in _budgets) {
      budget.spentAmount = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.category == budget.category &&
              t.dateTime.month == now.month &&
              t.dateTime.year == now.year)
          .fold(0.0, (sum, t) => sum + t.amount);
    }
  }

  Future<void> _saveState() async {
    final data = StorageData(
      transactionsJson: _transactions.map((t) => t.toJson()).toList(),
      budgetsJson: _budgets.map((b) => b.toJson()).toList(),
      assetsJson: _assets.map((a) => a.toJson()).toList(),
      investTransactionsJson: _investmentTransactions.map((it) => it.toJson()).toList(),
      cashReserves: _cashReserves,
      locale: _locale,
      remindersEnabled: _remindersEnabled,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      selectedCurrency: _selectedCurrency,
      exchangeRates: _exchangeRates,
      categoriesJson: _categories.map((c) => c.toJson()).toList(),
      themeMode: _themeName,
      adsEnabled: _adsEnabled,
      isGoldThemeUnlocked: _isGoldThemeUnlocked,
      currentVersion: _currentVersion,
    );
    await _storageService.saveData(data);
  }

  // --- Transactions management ---

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    _recalculateBudgetSpent();
    _saveState();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _recalculateBudgetSpent();
    _saveState();
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _recalculateBudgetSpent();
      _saveState();
      notifyListeners();
    }
  }

  // --- Budgets management ---

  void addBudget(Budget budget) {
    final index = _budgets.indexWhere((b) => b.category == budget.category);
    if (index != -1) {
      // Update existing limit
      _budgets[index] = Budget(
        id: _budgets[index].id,
        category: budget.category,
        limitAmount: budget.limitAmount,
        spentAmount: _budgets[index].spentAmount,
      );
    } else {
      _budgets.add(budget);
    }
    _recalculateBudgetSpent();
    _saveState();
    notifyListeners();
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    _saveState();
    notifyListeners();
  }

  // --- Investments management (Trading Simulator) ---

  bool buyAsset(String ticker, double quantity) {
    final assetIndex = _assets.indexWhere((a) => a.ticker == ticker);
    if (assetIndex == -1) return false;
    
    final asset = _assets[assetIndex];
    final cost = quantity * asset.currentPrice;

    if (_cashReserves < cost) {
      return false; // Insufficient Cash Wallet funds
    }

    _cashReserves -= cost;

    // Recalculate average buy price and owned quantity
    final double currentQty = asset.totalQuantity;
    final double currentAvgPrice = asset.averageBuyPrice;
    
    final double newQty = currentQty + quantity;
    final double newAvgPrice = ((currentAvgPrice * currentQty) + (asset.currentPrice * quantity)) / newQty;

    asset.totalQuantity = newQty;
    asset.averageBuyPrice = newAvgPrice;

    // Record Transaction
    final transaction = InvestmentTransaction(
      id: 'it_${DateTime.now().millisecondsSinceEpoch}',
      assetTicker: ticker,
      type: InvestmentType.buy,
      quantity: quantity,
      pricePerUnit: asset.currentPrice,
      dateTime: DateTime.now(),
    );
    _investmentTransactions.insert(0, transaction);

    _saveState();
    notifyListeners();
    return true;
  }

  bool sellAsset(String ticker, double quantity) {
    final assetIndex = _assets.indexWhere((a) => a.ticker == ticker);
    if (assetIndex == -1) return false;

    final asset = _assets[assetIndex];
    if (asset.totalQuantity < quantity) {
      return false; // Insufficient holdings
    }

    final double proceeds = quantity * asset.currentPrice;
    _cashReserves += proceeds;

    asset.totalQuantity -= quantity;
    if (asset.totalQuantity == 0) {
      asset.averageBuyPrice = 0.0;
    }

    // Record Transaction
    final transaction = InvestmentTransaction(
      id: 'it_${DateTime.now().millisecondsSinceEpoch}',
      assetTicker: ticker,
      type: InvestmentType.sell,
      quantity: quantity,
      pricePerUnit: asset.currentPrice,
      dateTime: DateTime.now(),
    );
    _investmentTransactions.insert(0, transaction);

    _saveState();
    notifyListeners();
    return true;
  }

  // --- Real-time Price Integration Engine ---

  Future<void> refreshPrices() async {
    _isLoading = true;
    notifyListeners();

    bool anySimulated = false;

    for (var asset in _assets) {
      final oldPrice = asset.currentPrice;
      final result = await _priceService.getPrice(asset.ticker, lastKnownPrice: oldPrice);
      
      asset.currentPrice = result.price;
      asset.changePercent = result.changePercent;
      
      // Maintain last 10 ticks for the visualization sparkline
      if (asset.historicalPrices.length >= 10) {
        asset.historicalPrices.removeAt(0);
      }
      asset.historicalPrices.add(result.price);

      if (!result.isLive) {
        anySimulated = true;
      }
    }

    // If even one ticker falls back to offline, we show Offline / Fallback in visual indicator
    _isLivePrices = !anySimulated;

    _isLoading = false;
    _saveState();
    notifyListeners();
  }

  // --- Real-Time Exchange Rate Engine ---

  Future<void> refreshExchangeRates() async {
    final rates = await _currencyService.fetchExchangeRates();
    if (rates.isNotEmpty) {
      _exchangeRates = rates;
      _saveState();
      notifyListeners();
    }
  }

  void setCurrency(String currencyCode) {
    if (_exchangeRates.containsKey(currencyCode)) {
      _selectedCurrency = currencyCode;
      _saveState();
      notifyListeners();
    }
  }

  double convertAmount(double amountInUSD) {
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    return amountInUSD * rate;
  }

  String formatAmount(double amountInUSD) {
    final rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    final converted = amountInUSD * rate;
    final symbol = CurrencyService.getCurrencySymbol(_selectedCurrency);

    if (_selectedCurrency == 'VND') {
      final formatted = converted.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '$formatted $symbol';
    } else {
      final formatted = converted.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '$symbol$formatted';
    }
  }

  // --- Dynamic Category Management ---

  void addCategory(String name, {required String icon, required int colorValue, bool isIncome = false}) {
    final id = 'cat_custom_${DateTime.now().millisecondsSinceEpoch}';
    final newCat = AppCategory(
      id: id,
      name: name,
      icon: icon,
      colorValue: colorValue,
      isCustom: true,
      isIncome: isIncome,
    );
    _categories.add(newCat);
    _saveState();
    notifyListeners();
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id && c.isCustom);
    _saveState();
    notifyListeners();
  }

  // --- Theme Mode management ---

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _themeName = mode == ThemeMode.dark ? 'dark' : 'light';
    _saveState();
    notifyListeners();
  }

  void setThemeName(String name) {
    if (name == 'gold' && !_isGoldThemeUnlocked) return;
    _themeName = name;
    _themeMode = name == 'light' ? ThemeMode.light : ThemeMode.dark;
    _saveState();
    notifyListeners();
  }

  // --- Sponsor Ads & Interstitial ---
  void setAdsEnabled(bool value) {
    _adsEnabled = value;
    _saveState();
    notifyListeners();
  }

  int _transactionLogCount = 0;

  void incrementTransactionCount(BuildContext context) {
    if (!_adsEnabled) return;
    _transactionLogCount++;
    if (_transactionLogCount >= 3) {
      _transactionLogCount = 0;
      // Show fullscreen premium interstitial ad overlay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          try {
            VibrantInterstitialAd.show(context, () {});
          } catch (e) {
            debugPrint('Interstitial show error: $e');
          }
        }
      });
    }
  }

  // --- Over-The-Air (OTA) Updates ---

  Future<void> checkOTAUpdates({bool silent = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final UpdateService updateService = UpdateService();
      final record = await updateService.checkForUpdates("https://example.com/ota-config");
      _latestVersion = record.version;
      _updateReleaseNotes = record.releaseNotes;
      _updateAvailable = _latestVersion != _currentVersion;
    } catch (e) {
      debugPrint('Check OTA failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> executeOTAUpdate(VoidCallback onInstalled) async {
    _isDownloadingUpdate = true;
    _downloadProgress = 0.0;
    _updateSuccess = false;
    notifyListeners();

    final UpdateService updateService = UpdateService();
    await updateService.runOTAUpdate(
      "https://example.com/apk",
      this,
      (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
      () {
        _currentVersion = _latestVersion;
        _isDownloadingUpdate = false;
        _updateAvailable = false;
        _updateSuccess = true;
        _isGoldThemeUnlocked = true;
        _saveState();
        notifyListeners();
        onInstalled();
      },
      (error) {
        _isDownloadingUpdate = false;
        notifyListeners();
      }
    );
  }

  // --- Dynamic settings & locale toggle ---

  void setLocale(String lang) {
    if (lang == 'en' || lang == 'vi') {
      _locale = lang;
      _saveState();
      updateNotificationSchedule();
      notifyListeners();
    }
  }

  void toggleLocale() {
    _locale = _locale == 'en' ? 'vi' : 'en';
    _saveState();
    updateNotificationSchedule();
    notifyListeners();
  }

  // --- OS Push Notifications Daily Schedule ---

  Future<void> updateNotificationSchedule() async {
    final ns = NotificationService();
    if (_remindersEnabled) {
      final String title = _locale == 'en' ? 'Daily Expense Reminder' : 'Nhắc nhở cập nhật chi tiêu';
      final String body = _locale == 'en'
          ? "Don't forget to record today's expenses and incomes to keep your budget healthy!"
          : "Đừng quên ghi chép lại các khoản thu chi hôm nay để giữ ngân sách luôn hợp lý nhé!";
      await ns.scheduleDailyReminder(
        id: 1,
        hour: _reminderHour,
        minute: _reminderMinute,
        title: title,
        body: body,
      );
    } else {
      await ns.cancelNotification(1);
    }
  }

  void setReminderSettings(bool enabled, int hour, int minute) {
    _remindersEnabled = enabled;
    _reminderHour = hour;
    _reminderMinute = minute;
    _saveState();
    updateNotificationSchedule();
    notifyListeners();
  }

  void triggerTestNotification() {
    final String title = _locale == 'en' ? 'Daily Expense Reminder' : 'Nhắc nhở cập nhật chi tiêu';
    final String body = _locale == 'en'
        ? "Don't forget to record today's expenses and incomes to keep your budget healthy!"
        : "Đừng quên ghi chép lại các khoản thu chi hôm nay để giữ ngân sách luôn hợp lý nhé!";
    NotificationService().showTestNotification(
      title: title,
      body: body,
    );
  }

  // Check if ledger remains empty today to trigger the evening prompt card
  bool get isLedgerEmptyToday {
    final now = DateTime.now();
    return !_transactions.any((t) =>
        t.dateTime.day == now.day &&
        t.dateTime.month == now.month &&
        t.dateTime.year == now.year &&
        t.type == TransactionType.expense);
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}
