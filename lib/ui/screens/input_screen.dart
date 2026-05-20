import 'package:flutter/material.dart';
import '../../models.dart';
import '../../localization.dart';
import '../../state/app_state.dart';
import '../widgets/custom_charts.dart';
import '../../services/currency_service.dart';
import '../../services/ad_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  AppCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'cash';

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _amountController.clear();
    _titleController.clear();
    _notesController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = null;
      _selectedPaymentMethod = 'cash';
    });
  }

  void _submitData(AppState state, String locale) {
    final double? amount = double.tryParse(_amountController.text);
    final String title = _titleController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('ui_error_invalid_amount', locale)),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('ui_error_invalid_title', locale)),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale == 'en' ? 'Please select a category' : 'Vui lòng chọn danh mục'),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    // Add transaction to AppState (automatically converted back if entered in different base rate)
    // All amounts in AppState database are stored as USD value base
    final double rate = state.exchangeRates[state.selectedCurrency] ?? 1.0;
    final double amountInUSD = amount / rate;

    // TODO: Connect this logged paymentMethod with external Open Banking/e-wallet APIs in the future
    final tx = Transaction(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amountInUSD,
      type: _selectedType,
      category: _selectedCategory!.name,
      dateTime: _selectedDate,
      notes: _notesController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
    );

    state.addTransaction(tx);
    _clearForm();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.translate('tr_transaction_saved', locale)),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Trigger interstitial ad every 3 successful transaction logs
    state.incrementTransactionCount(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark || state.themeName == 'gold';
    
    // Supported Categories filtered by type
    final filteredCategories = state.categories.where((c) => c.isIncome == (_selectedType == TransactionType.income)).toList();

    // Default select first category if none selected
    if (_selectedCategory == null && filteredCategories.isNotEmpty) {
      _selectedCategory = filteredCategories.first;
    } else if (_selectedCategory != null && _selectedCategory!.isIncome != (_selectedType == TransactionType.income)) {
      // Correct if type toggled
      _selectedCategory = filteredCategories.isNotEmpty ? filteredCategories.first : null;
    }

    // Calculate today's summary
    final now = DateTime.now();
    final todaysTx = state.transactions.where((t) =>
        t.dateTime.day == now.day &&
        t.dateTime.month == now.month &&
        t.dateTime.year == now.year).toList();
    
    final double todaysIncomeUSD = todaysTx
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double todaysExpenseUSD = todaysTx
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header greetings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale == 'en' ? 'Quick Ledger' : 'Ghi chép nhanh',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          locale == 'en' ? 'Add records instantly' : 'Ghi nhận giao dịch tức thời',
                          style: TextStyle(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    // Quick stats/currency badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isDark ? [] : [
                          const BoxShadow(color: Color(0x050F172A), blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        state.selectedCurrency,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount Entry Card (Highlighted widget)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedType == TransactionType.expense
                          ? [
                              AppColors.rose.withOpacity(isDark ? 0.16 : 0.1),
                              AppColors.rose.withOpacity(isDark ? 0.05 : 0.02)
                            ]
                          : [
                              AppColors.emerald.withOpacity(isDark ? 0.16 : 0.1),
                              AppColors.emerald.withOpacity(isDark ? 0.05 : 0.02)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _selectedType == TransactionType.expense
                          ? AppColors.rose.withOpacity(0.3)
                          : AppColors.emerald.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Text(
                        locale == 'en' ? 'ENTER AMOUNT' : 'NHẬP SỐ TIỀN',
                        style: TextStyle(
                          color: _selectedType == TransactionType.expense ? AppColors.rose : AppColors.emerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Highlights number entry
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            CurrencyService.getCurrencySymbol(state.selectedCurrency),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 44, fontWeight: FontWeight.bold),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Satisfying Sliding Toggle Switch between Expense & Income
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.expense;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.expense ? AppColors.rose : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.north_east_rounded,
                                  color: _selectedType == TransactionType.expense ? Colors.white : AppColors.rose,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.translate('tr_expense', locale),
                                  style: TextStyle(
                                    color: _selectedType == TransactionType.expense ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.income;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.income ? AppColors.emerald : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.south_west_rounded,
                                  color: _selectedType == TransactionType.income ? Colors.white : AppColors.emerald,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.translate('tr_income', locale),
                                  style: TextStyle(
                                    color: _selectedType == TransactionType.income ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Chips List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.translate('tr_category', locale),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddCategorySheet(context, state, locale, isDark),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, color: AppColors.violet, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            locale == 'en' ? 'Add Custom' : 'Thêm mới',
                            style: const TextStyle(
                              color: AppColors.violet,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Horiz Chips List
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      final isSelected = _selectedCategory?.id == cat.id;
                      final Color catColor = Color(cat.colorValue);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            border: Border.all(
                              color: isSelected ? catColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: isSelected
                                ? [BoxShadow(color: catColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(cat.icon),
                                color: isSelected ? Colors.white : catColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.isCustom ? cat.name : AppLocalizations.translate(_getCategoryLocalizationKey(cat.name), locale),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method Selector
                Text(
                  AppLocalizations.translate('tr_payment_method', locale),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPaymentMethodOption('cash', Icons.payments_rounded, AppColors.cyan, isDark, locale),
                    const SizedBox(width: 10),
                    _buildPaymentMethodOption('banking', Icons.account_balance_rounded, AppColors.violet, isDark, locale),
                    const SizedBox(width: 10),
                    _buildPaymentMethodOption('ewallet', Icons.account_balance_wallet_rounded, AppColors.emerald, isDark, locale),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locale == 'en'
                              ? 'TODO: Future automated integration with Open Banking APIs'
                              : 'TODO: Tự động đồng bộ với hệ thống ngân hàng & ví điện tử trong tương lai',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details Card (Title & Notes & Date)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isDark ? [] : [
                      const BoxShadow(color: Color(0x050F172A), blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      // Title
                      TextField(
                        controller: _titleController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.translate('tr_title', locale),
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.violet),
                          border: InputBorder.none,
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.violet)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Notes
                      TextField(
                        controller: _notesController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.translate('tr_notes', locale),
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.violet),
                          border: InputBorder.none,
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.violet)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date picker Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: AppColors.violet, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.translate('tr_date', locale),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: isDark
                                        ? ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.violet,
                                              surface: Color(0xFF1E293B),
                                            ),
                                          )
                                        : ThemeData.light().copyWith(
                                            colorScheme: const ColorScheme.light(
                                              primary: AppColors.violet,
                                            ),
                                          ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      shadowColor: AppColors.violet.withOpacity(0.4),
                    ),
                    onPressed: () => _submitData(state, locale),
                    child: Text(
                      AppLocalizations.translate('tr_add_transaction', locale),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sponsor Banner Ad (premium non-intrusive placement)
                const SponsorBannerAd(),

                // Today's cash flow highlights
                Text(
                  locale == 'en' ? "Today's Status" : "Tình hình hôm nay",
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallSummaryCard(
                        title: AppLocalizations.translate('tr_income', locale),
                        amount: state.formatAmount(todaysIncomeUSD),
                        color: AppColors.emerald,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSmallSummaryCard(
                        title: AppLocalizations.translate('tr_expense', locale),
                        amount: state.formatAmount(todaysExpenseUSD),
                        color: AppColors.rose,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // List of today's logged transactions
                if (todaysTx.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale == 'en' ? "Logged Today" : "Ghi nhận hôm nay",
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todaysTx.length > 3 ? 3 : todaysTx.length,
                    itemBuilder: (context, index) {
                      final tx = todaysTx[index];
                      final isExpense = tx.type == TransactionType.expense;
                      final amtColor = isExpense ? AppColors.rose : AppColors.emerald;
                      final prefix = isExpense ? '-' : '+';
                      final dynamicCat = state.categories.firstWhere((c) => c.name == tx.category, orElse: () => state.categories.first);
                      final Color catColor = Color(dynamicCat.colorValue);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
                              color: catColor,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            tx.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            tx.category,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$prefix${state.formatAmount(tx.amount)}',
                                style: TextStyle(
                                  color: amtColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                                onPressed: () {
                                  _showDeleteConfirm(context, state, tx.id, locale);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallSummaryCard({required String title, required String amount, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          const BoxShadow(color: Color(0x040F172A), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'receipt':
        return Icons.receipt;
      case 'payments':
        return Icons.payments;
      case 'trending_up':
        return Icons.trending_up;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'medical_services':
        return Icons.medical_services;
      case 'flight':
        return Icons.flight;
      case 'pets':
        return Icons.pets;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'more_horiz':
      default:
        return Icons.more_horiz;
    }
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

  void _showAddCategorySheet(BuildContext context, AppState state, String locale, bool isDark) {
    final TextEditingController nameController = TextEditingController();
    TransactionType catType = _selectedType;
    String selectedIcon = 'restaurant';
    Color selectedColor = AppColors.violet;

    final List<String> availableIcons = [
      'restaurant',
      'directions_car',
      'shopping_bag',
      'sports_esports',
      'receipt',
      'payments',
      'trending_up',
      'home',
      'school',
      'medical_services',
      'flight',
      'pets',
      'card_giftcard'
    ];

    final List<Color> availableColors = [
      AppColors.rose,
      AppColors.violet,
      AppColors.amber,
      AppColors.cyan,
      AppColors.emerald,
      const Color(0xFF6366F1), // Indigo
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale == 'en' ? 'Add Custom Category' : 'Thêm danh mục mới',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Name Input
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: locale == 'en' ? 'Category Name' : 'Tên danh mục',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.category_rounded, color: AppColors.violet),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.violet)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.translate('tr_type', locale),
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.translate('tr_expense', locale),
                              style: TextStyle(color: catType == TransactionType.expense ? Colors.white : Colors.grey),
                            ),
                            selected: catType == TransactionType.expense,
                            selectedColor: AppColors.rose,
                            onSelected: (val) {
                              if (val) setModalState(() => catType = TransactionType.expense);
                            },
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Text(
                              AppLocalizations.translate('tr_income', locale),
                              style: TextStyle(color: catType == TransactionType.income ? Colors.white : Colors.grey),
                            ),
                            selected: catType == TransactionType.income,
                            selectedColor: AppColors.emerald,
                            onSelected: (val) {
                              if (val) setModalState(() => catType = TransactionType.income);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Icon Grid Selector
                  Text(
                    locale == 'en' ? 'Select Icon' : 'Chọn Biểu tượng',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? selectedColor : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? selectedColor : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(icon),
                              color: isSelected ? Colors.white : selectedColor,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Color Picker Selector
                  Text(
                    locale == 'en' ? 'Select Color' : 'Chọn Màu sắc',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableColors.length,
                      itemBuilder: (context, index) {
                        final color = availableColors[index];
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(locale == 'en' ? 'Please enter a name' : 'Vui lòng nhập tên danh mục'),
                              backgroundColor: AppColors.rose,
                            ),
                          );
                          return;
                        }
                        // Add custom category
                        state.addCategory(
                          name,
                          icon: selectedIcon,
                          colorValue: selectedColor.value,
                          isIncome: catType == TransactionType.income,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.translate('ui_save', locale),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, AppState state, String id, String locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: state.themeMode == ThemeMode.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          AppLocalizations.translate('tr_delete_confirm', locale),
          style: TextStyle(color: state.themeMode == ThemeMode.dark ? Colors.white : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.translate('tr_delete_confirm_body', locale),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.translate('ui_cancel', locale), style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(AppLocalizations.translate('ui_delete', locale), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold)),
            onPressed: () {
              state.deleteTransaction(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(String method, IconData icon, Color activeColor, bool isDark, String locale) {
    final isSelected = _selectedPaymentMethod == method;
    String label = '';
    if (method == 'cash') {
      label = AppLocalizations.translate('tr_cash', locale);
    } else if (method == 'banking') {
      label = AppLocalizations.translate('tr_banking', locale);
    } else if (method == 'ewallet') {
      label = AppLocalizations.translate('tr_ewallet', locale);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(isDark ? 0.2 : 0.15)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
