import 'package:flutter/material.dart';
import '../../models.dart';
import '../../localization.dart';
import '../../state/app_state.dart';
import '../../services/currency_service.dart';
import '../widgets/custom_charts.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String _activeFilter = 'all'; // 'all', 'healthy', 'exceeded'
  String _activeSort = 'name'; // 'name', 'limit', 'percent'
  
  void _showAddBudgetDialog(BuildContext context, AppState state, {Budget? budgetToEdit}) {
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final rate = state.exchangeRates[state.selectedCurrency] ?? 1.0;
    
    // Fetch expense categories dynamically
    final dynamicCategories = state.categories
        .where((c) => !c.isIncome)
        .map((c) => c.name)
        .toList();
    if (dynamicCategories.isEmpty) {
      dynamicCategories.add('Other Details');
    }

    final List<String> dropdownItems = List<String>.from(dynamicCategories);
    String selectedCategory = budgetToEdit?.category ?? dropdownItems.first;
    if (budgetToEdit != null && !dropdownItems.contains(budgetToEdit.category)) {
      dropdownItems.add(budgetToEdit.category);
    }

    final limitController = TextEditingController(
      text: budgetToEdit != null
          ? (budgetToEdit.limitAmount * rate).toStringAsFixed(state.selectedCurrency == 'VND' ? 0 : 2)
          : '',
    );
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.translate(
                          budgetToEdit == null ? 'bg_add_budget' : 'bg_edit_budget',
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
                  const SizedBox(height: 24),

                  // Category Selector
                  Text(
                    AppLocalizations.translate('tr_category', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        dropdownColor: cardColor,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
                        isExpanded: true,
                        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                        items: dropdownItems.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: budgetToEdit != null ? null : (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Limit Field
                  Text(
                    AppLocalizations.translate('bg_limit', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'e.g. 500.00',
                      hintStyle: TextStyle(color: mutedTextColor),
                      prefixText: state.selectedCurrency != 'VND'
                          ? '${CurrencyService.getCurrencySymbol(state.selectedCurrency)} '
                          : null,
                      prefixStyle: TextStyle(color: textColor, fontSize: 16),
                      suffixText: state.selectedCurrency == 'VND'
                          ? ' ${CurrencyService.getCurrencySymbol(state.selectedCurrency)}'
                          : null,
                      suffixStyle: TextStyle(color: textColor, fontSize: 16),
                      filled: true,
                      fillColor: backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.violet, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.rose, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Actions Buttons
                  Row(
                    children: [
                      if (budgetToEdit != null) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: AppColors.rose, size: 28),
                          onPressed: () {
                            _showDeleteConfirm(context, state, budgetToEdit.id);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            final limit = double.tryParse(limitController.text.trim());
                            if (limit == null || limit <= 0) {
                              setModalState(() {
                                errorMessage = AppLocalizations.translate('ui_error_invalid_amount', locale);
                              });
                              return;
                            }

                            // Convert limit from current currency back to USD baseline for storage
                            final double limitInUSD = limit / rate;

                            final newBudget = Budget(
                              id: budgetToEdit?.id ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
                              category: selectedCategory,
                              limitAmount: limitInUSD,
                            );

                            state.addBudget(newBudget);
                            Navigator.pop(context);
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
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, AppState state, String id) {
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(AppLocalizations.translate('bg_delete_confirm', locale), style: TextStyle(color: textColor)),
        content: Text(AppLocalizations.translate('bg_delete_confirm_body', locale), style: TextStyle(color: mutedTextColor)),
        actions: [
          TextButton(
            child: Text(AppLocalizations.translate('ui_cancel', locale), style: TextStyle(color: textColor.withOpacity(0.8))),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: Text(AppLocalizations.translate('ui_delete', locale), style: const TextStyle(color: Colors.white)),
            onPressed: () {
              state.deleteBudget(id);
              // pop dialog
              Navigator.pop(context);
              // pop bottom sheet
              Navigator.pop(context);
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

    // Filter Logic
    List<Budget> filteredBudgets = state.budgets.where((b) {
      if (_activeFilter == 'healthy') return !b.isExceeded;
      if (_activeFilter == 'exceeded') return b.isExceeded;
      return true;
    }).toList();

    // Sort Logic
    filteredBudgets.sort((a, b) {
      if (_activeSort == 'limit') {
        return b.limitAmount.compareTo(a.limitAmount);
      } else if (_activeSort == 'percent') {
        return b.percentage.compareTo(a.percentage);
      } else {
        // Name A-Z
        return a.category.compareTo(b.category);
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.translate('bg_budget_title', locale),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        locale == 'en'
                            ? 'Set visual limits and keep savings healthy'
                            : 'Thiết lập giới hạn chi tiêu và tích lũy hợp lý',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Add Budget Trigger
                  GestureDetector(
                    onTap: () => _showAddBudgetDialog(context, state),
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
              const SizedBox(height: 24),

              // Filter Tabs Header
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: AppLocalizations.translate('bg_status_all', locale),
                      filterKey: 'all',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: AppLocalizations.translate('bg_status_healthy', locale),
                      filterKey: 'healthy',
                      activeColor: AppColors.emerald,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: AppLocalizations.translate('bg_status_exceeded', locale),
                      filterKey: 'exceeded',
                      activeColor: AppColors.rose,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sort dropdown panel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredBudgets.length} ${locale == 'en' ? 'budgets' : 'ngân sách'}',
                    style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.translate('tr_sort_by', locale)}: ',
                        style: TextStyle(color: mutedTextColor, fontSize: 13),
                      ),
                      DropdownButton<String>(
                        value: _activeSort,
                        dropdownColor: cardColor,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.violet),
                        style: const TextStyle(color: AppColors.violet, fontSize: 13, fontWeight: FontWeight.bold),
                        items: [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text(AppLocalizations.translate('bg_sort_name', locale)),
                          ),
                          DropdownMenuItem(
                            value: 'limit',
                            child: Text(AppLocalizations.translate('bg_sort_limit', locale)),
                          ),
                          DropdownMenuItem(
                            value: 'percent',
                            child: Text(AppLocalizations.translate('bg_sort_percent', locale)),
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Budget List Display
              Expanded(
                child: filteredBudgets.isEmpty
                    ? _buildEmptyState(locale, cardColor, mutedTextColor)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredBudgets.length,
                        itemBuilder: (context, index) {
                          final budget = filteredBudgets[index];
                          return _buildBudgetCard(
                            context,
                            state,
                            budget,
                            locale,
                            cardColor,
                            borderColor,
                            textColor,
                            mutedTextColor,
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedTextColor,
    Color activeColor = AppColors.violet,
  }) {
    final bool isActive = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : cardColor,
          border: Border.all(
            color: isActive ? activeColor : borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : activeColor) : mutedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
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
            child: Icon(Icons.pie_chart_outline_rounded, color: mutedTextColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.translate('bg_empty_budget', locale),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    AppState state,
    Budget budget,
    String locale,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    final double pct = budget.percentage;
    final bool exceeded = budget.isExceeded;
    
    // Dynamic formatting of spent, limit and remaining amounts using active exchange rates
    final String remainingText = exceeded
        ? '${AppLocalizations.translate('bg_over_budget', locale)} ${state.formatAmount(budget.spentAmount - budget.limitAmount)}'
        : '${AppLocalizations.translate('bg_remaining', locale)} ${state.formatAmount(budget.limitAmount - budget.spentAmount)}';

    // Premium Color Coding based on usage percent
    Color progressColor;
    if (pct >= 1.0) {
      progressColor = AppColors.rose;
    } else if (pct >= 0.75) {
      progressColor = AppColors.amber;
    } else {
      progressColor = AppColors.emerald;
    }

    // Get color dynamically, supporting custom categories
    final categoryColor = AppColors.getCategoryColor(budget.category, dynamicCategories: state.categories);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                const BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    budget.category,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showAddBudgetDialog(context, state, budgetToEdit: budget),
                child: Icon(Icons.more_horiz_rounded, color: textColor),
              )
            ],
          ),
          const SizedBox(height: 18),

          // Numbers Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.translate('bg_spent', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.formatAmount(budget.spentAmount),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.translate('bg_limit', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.formatAmount(budget.limitAmount),
                    style: TextStyle(
                      color: textColor.withOpacity(0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 14),

          // Gorgeous Gradient Progress Bar
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double progressWidth = constraints.maxWidth * (pct > 1.0 ? 1.0 : pct);
                  return Container(
                    width: progressWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor.withOpacity(0.7),
                          progressColor,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status & Remaining calculation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                remainingText,
                style: TextStyle(
                  color: exceeded ? AppColors.rose : mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
