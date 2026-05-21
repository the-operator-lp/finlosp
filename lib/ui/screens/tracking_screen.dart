import 'package:flutter/material.dart';
import '../../models.dart';
import '../../localization.dart';
import '../../state/app_state.dart';
import '../widgets/custom_charts.dart';
import '../../services/currency_service.dart';
import '../../services/ad_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', 'expense', 'income'
  String _categoryFilter = 'all';
  String _activeSort = 'date_new'; // 'date_new', 'date_old', 'amount_high', 'amount_low'

  // Helper to format Date nicely
  String _formatDate(DateTime date, String locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return locale == 'en' ? 'Today' : 'Hôm nay';
    } else if (checkDate == yesterday) {
      return locale == 'en' ? 'Yesterday' : 'Hôm qua';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  void _showTransactionEditor(BuildContext context, AppState state, {Transaction? transactionToEdit}) {
    final locale = state.locale;
    final isEdit = transactionToEdit != null;

    final titleController = TextEditingController(text: transactionToEdit?.title ?? '');
    
    // Convert USD value from DB to active selected currency value for display in editing
    final double rate = state.exchangeRates[state.selectedCurrency] ?? 1.0;
    final double initialAmount = transactionToEdit != null ? (transactionToEdit.amount * rate) : 0.0;
    
    final amountController = TextEditingController(
      text: transactionToEdit != null 
          ? (state.selectedCurrency == 'VND' ? initialAmount.toStringAsFixed(0) : initialAmount.toStringAsFixed(2))
          : '',
    );
    final notesController = TextEditingController(text: transactionToEdit?.notes ?? '');
    
    TransactionType selectedType = transactionToEdit?.type ?? TransactionType.expense;
    DateTime selectedDate = transactionToEdit?.dateTime ?? DateTime.now();
    String selectedPaymentMethod = transactionToEdit?.paymentMethod ?? 'cash';
    
    // Get dynamic active categories list based on selected transaction type
    List<AppCategory> activeCategories = state.categories.where((c) => c.isIncome == (selectedType == TransactionType.income)).toList();
    AppCategory? selectedCategory;
    
    if (transactionToEdit != null) {
      selectedCategory = state.categories.firstWhere(
        (c) => c.name == transactionToEdit.category,
        orElse: () => activeCategories.isNotEmpty ? activeCategories.first : state.categories.first,
      );
    } else {
      selectedCategory = activeCategories.isNotEmpty ? activeCategories.first : null;
    }

    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: state.themeMode == ThemeMode.dark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = state.themeMode == ThemeMode.dark;
            final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
            final modalBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
            final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

            // Recalculate based on selected type
            activeCategories = state.categories.where((c) => c.isIncome == (selectedType == TransactionType.income)).toList();
            if (selectedCategory == null || selectedCategory!.isIncome != (selectedType == TransactionType.income)) {
              selectedCategory = activeCategories.isNotEmpty ? activeCategories.first : null;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.translate(
                            isEdit ? 'tr_edit_transaction' : 'tr_add_transaction',
                            locale,
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.close_rounded, color: textColor, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Type Toggle (Expense / Income)
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTypeOption(
                            label: AppLocalizations.translate('tr_expense', locale),
                            isActive: selectedType == TransactionType.expense,
                            color: AppColors.rose,
                            modalBgColor: modalBgColor,
                            borderColor: borderColor,
                            mutedTextColor: mutedTextColor,
                            onTap: () {
                              setModalState(() {
                                selectedType = TransactionType.expense;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModalTypeOption(
                            label: AppLocalizations.translate('tr_income', locale),
                            isActive: selectedType == TransactionType.income,
                            color: AppColors.emerald,
                            modalBgColor: modalBgColor,
                            borderColor: borderColor,
                            mutedTextColor: mutedTextColor,
                            onTap: () {
                              setModalState(() {
                                selectedType = TransactionType.income;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      AppLocalizations.translate('tr_title', locale),
                      style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Grocery dinner',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: modalBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.violet, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    Text(
                      AppLocalizations.translate('tr_amount', locale),
                      style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: mutedTextColor),
                        prefixText: '${CurrencyService.getCurrencySymbol(state.selectedCurrency)} ',
                        prefixStyle: TextStyle(color: textColor, fontSize: 15),
                        filled: true,
                        fillColor: modalBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.violet, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category & Date in side-by-side row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.translate('tr_category', locale),
                                style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: modalBgColor,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<AppCategory>(
                                    value: selectedCategory,
                                    dropdownColor: cardColor,
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down, color: textColor),
                                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                                    items: activeCategories.map((c) {
                                      return DropdownMenuItem<AppCategory>(
                                        value: c,
                                        child: Text(c.isCustom ? c.name : AppLocalizations.translate(_getCategoryLocalizationKey(c.name), locale)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedCategory = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.translate('tr_date', locale),
                                style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    builder: (context, child) {
                                      return Theme(
                                        data: isDark
                                            ? ThemeData.dark().copyWith(
                                                colorScheme: const ColorScheme.dark(
                                                  primary: AppColors.violet,
                                                  onPrimary: Colors.white,
                                                  surface: Color(0xFF1E293B),
                                                  onSurface: Colors.white,
                                                ),
                                              )
                                            : ThemeData.light().copyWith(
                                                colorScheme: const ColorScheme.light(
                                                  primary: AppColors.violet,
                                                  onPrimary: Colors.white,
                                                  surface: Colors.white,
                                                  onSurface: Color(0xFF0F172A),
                                                ),
                                              ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setModalState(() {
                                      selectedDate = date;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: modalBgColor,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                        style: TextStyle(color: textColor, fontSize: 14),
                                      ),
                                      const Icon(Icons.calendar_month_rounded, color: AppColors.violet, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Method selector
                    Text(
                      AppLocalizations.translate('tr_payment_method', locale),
                      style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildModalPaymentMethodOption(
                          method: 'cash',
                          icon: Icons.payments_rounded,
                          activeColor: AppColors.cyan,
                          currentMethod: selectedPaymentMethod,
                          isDark: isDark,
                          locale: locale,
                          onTap: () {
                            setModalState(() {
                              selectedPaymentMethod = 'cash';
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildModalPaymentMethodOption(
                          method: 'banking',
                          icon: Icons.account_balance_rounded,
                          activeColor: AppColors.violet,
                          currentMethod: selectedPaymentMethod,
                          isDark: isDark,
                          locale: locale,
                          onTap: () {
                            setModalState(() {
                              selectedPaymentMethod = 'banking';
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildModalPaymentMethodOption(
                          method: 'ewallet',
                          icon: Icons.account_balance_wallet_rounded,
                          activeColor: AppColors.emerald,
                          currentMethod: selectedPaymentMethod,
                          isDark: isDark,
                          locale: locale,
                          onTap: () {
                            setModalState(() {
                              selectedPaymentMethod = 'ewallet';
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildModalPaymentMethodOption(
                          method: 'crypto',
                          icon: Icons.currency_exchange_rounded,
                          activeColor: Colors.orangeAccent,
                          currentMethod: selectedPaymentMethod,
                          isDark: isDark,
                          locale: locale,
                          onTap: () {
                            setModalState(() {
                              selectedPaymentMethod = 'crypto';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text(
                      AppLocalizations.translate('tr_notes', locale),
                      style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: textColor, fontSize: 15),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Notes / Context...',
                        hintStyle: TextStyle(color: mutedTextColor),
                        filled: true,
                        fillColor: modalBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.violet, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: AppColors.rose, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        if (isEdit) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.rose, size: 28),
                            onPressed: () => _showDeleteConfirm(context, state, transactionToEdit.id),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.violet,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              final title = titleController.text.trim();
                              final amt = double.tryParse(amountController.text);

                              if (title.isEmpty) {
                                setModalState(() {
                                  errorMessage = AppLocalizations.translate('ui_error_invalid_title', locale);
                                });
                                return;
                              }

                              if (amt == null || amt <= 0) {
                                setModalState(() {
                                  errorMessage = AppLocalizations.translate('ui_error_invalid_amount', locale);
                                });
                                return;
                              }

                              if (selectedCategory == null) {
                                setModalState(() {
                                  errorMessage = locale == 'en' ? 'Category is required' : 'Danh mục là bắt buộc';
                                });
                                return;
                              }

                              // Convert amount back to baseline USD before storing
                              final double amountInUSD = amt / rate;

                              final tx = Transaction(
                                id: transactionToEdit?.id ?? 't_${DateTime.now().millisecondsSinceEpoch}',
                                title: title,
                                amount: amountInUSD,
                                type: selectedType,
                                category: selectedCategory!.name,
                                dateTime: selectedDate,
                                notes: notesController.text.trim(),
                                paymentMethod: selectedPaymentMethod,
                              );

                              if (isEdit) {
                                state.updateTransaction(tx);
                              } else {
                                state.addTransaction(tx);
                              }

                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.translate('tr_transaction_saved', locale)),
                                  backgroundColor: AppColors.emerald,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.translate('ui_save', locale),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalTypeOption({
    required String label,
    required bool isActive,
    required Color color,
    required Color modalBgColor,
    required Color borderColor,
    required Color mutedTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : modalBgColor,
          border: Border.all(
            color: isActive ? color : borderColor,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : mutedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getCategoryLocalizationKey(String name) {
    switch (name) {
      case 'Food & Drinks':
        return 'cat_food';
      case 'Transportation':
        return 'cat_transport';
      case 'Bills & Utilities':
        return 'cat_utilities';
      case 'Shopping':
        return 'cat_shopping';
      case 'Entertainment':
        return 'cat_entertainment';
      case 'Salary Income':
        return 'cat_salary';
      case 'Invest Dividends':
        return 'cat_dividends';
      case 'Other Details':
      default:
        return 'cat_other';
    }
  }

  void _showDeleteConfirm(BuildContext context, AppState state, String id) {
    final locale = state.locale;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: state.themeMode == ThemeMode.dark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(AppLocalizations.translate('tr_delete_confirm', locale), style: TextStyle(color: state.themeMode == ThemeMode.dark ? Colors.white : const Color(0xFF0F172A))),
        content: Text(AppLocalizations.translate('tr_delete_confirm_body', locale), style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            child: Text(AppLocalizations.translate('ui_cancel', locale), style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: Text(AppLocalizations.translate('ui_delete', locale), style: const TextStyle(color: Colors.white)),
            onPressed: () {
              state.deleteTransaction(id);
              // pop dialog
              Navigator.pop(context);
              // pop bottom sheet
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.translate('tr_transaction_deleted', locale)),
                  backgroundColor: AppColors.rose,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark;

    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    // Fuzzy matching & category & type Filtering logic
    List<Transaction> items = state.transactions.where((item) {
      // Type filter
      if (_typeFilter == 'expense' && item.type != TransactionType.expense) return false;
      if (_typeFilter == 'income' && item.type != TransactionType.income) return false;

      // Category filter
      if (_categoryFilter != 'all' && item.category != _categoryFilter) return false;

      // Search Query fuzzy filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesCat = item.category.toLowerCase().contains(q);
        if (!matchesTitle && !matchesCat) return false;
      }

      return true;
    }).toList();

    // Sorting Logic
    items.sort((a, b) {
      if (_activeSort == 'date_old') {
        return a.dateTime.compareTo(b.dateTime);
      } else if (_activeSort == 'amount_high') {
        return b.amount.compareTo(a.amount);
      } else if (_activeSort == 'amount_low') {
        return a.amount.compareTo(b.amount);
      } else {
        // Newest First
        return b.dateTime.compareTo(a.dateTime);
      }
    });

    // Grouping by Date for visual lists
    final Map<String, List<Transaction>> groupedItems = {};
    for (var item in items) {
      final dateKey = _formatDate(item.dateTime, locale);
      groupedItems[dateKey] = (groupedItems[dateKey] ?? [])..add(item);
    }

    // Get active categories to populate quick category filter chips list
    final List<AppCategory> dynamicFilterCategories = state.categories;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Ledger Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.translate('tr_ledger_title', locale),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        locale == 'en' ? 'Track income and monitor daily transactions' : 'Theo dõi thu nhập và quản lý chi tiêu hàng ngày',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showTransactionEditor(context, state),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar & Filter Panel
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  style: TextStyle(color: textColor),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.translate('tr_search_placeholder', locale),
                    hintStyle: TextStyle(color: mutedTextColor),
                    prefixIcon: Icon(Icons.search_rounded, color: mutedTextColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type Filters row
              Row(
                children: [
                  Expanded(
                    child: _buildTypeToggleChip(
                      label: AppLocalizations.translate('tr_all', locale),
                      typeKey: 'all',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeToggleChip(
                      label: AppLocalizations.translate('tr_expense', locale),
                      typeKey: 'expense',
                      activeColor: AppColors.rose,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeToggleChip(
                      label: AppLocalizations.translate('tr_income', locale),
                      typeKey: 'income',
                      activeColor: AppColors.emerald,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal Category filter sliding list
              if (dynamicFilterCategories.isNotEmpty) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildCategoryChip('All', 'all', cardColor, borderColor, mutedTextColor),
                      ...dynamicFilterCategories.map((c) => _buildCategoryChip(
                            c.isCustom ? c.name : AppLocalizations.translate(_getCategoryLocalizationKey(c.name), locale),
                            c.name,
                            cardColor,
                            borderColor,
                            mutedTextColor,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Sorting Selection header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    locale == 'en' ? '${items.length} records found' : 'Tìm thấy ${items.length} bản ghi',
                    style: TextStyle(color: mutedTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.translate('tr_sort_by', locale)}: ',
                        style: TextStyle(color: mutedTextColor, fontSize: 12),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _activeSort,
                          dropdownColor: cardColor,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.violet),
                          style: const TextStyle(color: AppColors.violet, fontSize: 12, fontWeight: FontWeight.bold),
                          items: [
                            DropdownMenuItem(
                              value: 'date_new',
                              child: Text(AppLocalizations.translate('tr_sort_date_new', locale)),
                            ),
                            DropdownMenuItem(
                              value: 'date_old',
                              child: Text(AppLocalizations.translate('tr_sort_date_old', locale)),
                            ),
                            DropdownMenuItem(
                              value: 'amount_high',
                              child: Text(AppLocalizations.translate('tr_sort_amount_high', locale)),
                            ),
                            DropdownMenuItem(
                              value: 'amount_low',
                              child: Text(AppLocalizations.translate('tr_sort_amount_low', locale)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _activeSort = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Ledger Transactions List Grouped by Day
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(locale, cardColor, mutedTextColor)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: groupedItems.keys.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedItems.keys.elementAt(index);
                          final dayTransactions = groupedItems[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  dateKey,
                                  style: TextStyle(
                                    color: mutedTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  border: Border.all(color: borderColor, width: 1),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: dayTransactions.length,
                                  separatorBuilder: (context, idx) => Divider(
                                    color: borderColor.withOpacity(0.5),
                                    height: 1,
                                  ),
                                  itemBuilder: (context, idx) {
                                    final tx = dayTransactions[idx];
                                    final isExpense = tx.type == TransactionType.expense;
                                    final categoryColor = AppColors.getCategoryColor(tx.category, dynamicCategories: state.categories);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
                                          color: categoryColor,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        tx.title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        tx.category,
                                        style: TextStyle(
                                          color: mutedTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${isExpense ? '-' : '+'}${state.formatAmount(tx.amount)}',
                                        style: TextStyle(
                                          color: isExpense ? AppColors.rose : AppColors.emerald,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onTap: () => _showTransactionEditor(context, state, transactionToEdit: tx),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const SponsorBannerAd(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggleChip({
    required String label,
    required String typeKey,
    required Color cardColor,
    required Color borderColor,
    required Color mutedTextColor,
    Color activeColor = AppColors.violet,
  }) {
    final bool isActive = _typeFilter == typeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _typeFilter = typeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : cardColor,
          border: Border.all(
            color: isActive ? activeColor : borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : mutedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String displayName, String categoryKey, Color cardColor, Color borderColor, Color mutedTextColor) {
    final bool isActive = _categoryFilter == categoryKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoryFilter = categoryKey;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.violet.withOpacity(0.12) : cardColor,
          border: Border.all(
            color: isActive ? AppColors.violet : borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            color: isActive ? AppColors.violet : mutedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String locale, Color cardColor, Color mutedTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, color: mutedTextColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.translate('tr_empty_ledger', locale),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalPaymentMethodOption({
    required String method,
    required IconData icon,
    required Color activeColor,
    required String currentMethod,
    required bool isDark,
    required String locale,
    required VoidCallback onTap,
  }) {
    final isSelected = currentMethod == method;
    String label = '';
    if (method == 'cash') {
      label = AppLocalizations.translate('tr_cash', locale);
    } else if (method == 'banking') {
      label = AppLocalizations.translate('tr_banking', locale);
    } else if (method == 'ewallet') {
      label = AppLocalizations.translate('tr_ewallet', locale);
    } else if (method == 'crypto') {
      label = AppLocalizations.translate('tr_crypto', locale);
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(isDark ? 0.2 : 0.15)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
