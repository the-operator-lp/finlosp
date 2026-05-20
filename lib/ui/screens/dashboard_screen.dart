import 'package:flutter/material.dart';
import '../../models.dart';
import '../../localization.dart';
import '../../state/app_state.dart';
import '../widgets/custom_charts.dart';
import '../../services/ad_service.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToLedger;

  const DashboardScreen({super.key, required this.onNavigateToLedger});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark || state.themeName == 'gold';

    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final String balanceText = state.formatAmount(state.netWorth);
    final String cashText = state.formatAmount(state.cashReserves);
    final String portfolioText = state.formatAmount(state.totalPortfolioValue);
    final String incomeText = state.formatAmount(state.monthlyIncome);
    final String expenseText = state.formatAmount(state.monthlyExpense);

    // Prepare data for the Allocation Ring Chart (monthly category spend)
    final Map<String, double> categorySpends = {};
    for (var t in state.transactions) {
      if (t.type == TransactionType.expense) {
        categorySpends[t.category] = (categorySpends[t.category] ?? 0) + t.amount;
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile & Localization Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate('nav_dashboard', locale),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${AppLocalizations.translate('db_net_worth', locale)} overview',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Language Switcher Badge
                        GestureDetector(
                          onTap: state.toggleLocale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              border: Border.all(color: borderColor, width: 1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.language, color: AppColors.emerald, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  state.locale == 'en' ? 'EN' : 'VI',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Settings button
                        GestureDetector(
                          onTap: () => _showSettingsSheet(context, state, locale, isDark, cardColor, borderColor, textColor, mutedTextColor),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              border: Border.all(color: borderColor, width: 1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings_rounded, color: AppColors.violet, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Evening Ledger Reminder Banner
                if (state.isLedgerEmptyToday)
                  _buildReminderBanner(context, state, locale, cardColor, borderColor, textColor, mutedTextColor),

                // Core Net Worth Display Card
                _buildNetWorthCard(context, balanceText, cashText, portfolioText, locale),
                const SizedBox(height: 20),

                // Income vs Expense Highlights
                Row(
                  children: [
                    Expanded(
                      child: _buildFlowHighlightCard(
                        title: AppLocalizations.translate('db_monthly_income', locale),
                        amount: incomeText,
                        color: AppColors.emerald,
                        icon: Icons.south_west_rounded,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildFlowHighlightCard(
                        title: AppLocalizations.translate('db_monthly_expense', locale),
                        amount: expenseText,
                        color: AppColors.rose,
                        icon: Icons.north_east_rounded,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Spending allocation
                if (categorySpends.isNotEmpty) ...[
                  Text(
                    AppLocalizations.translate('st_expense_allocation', locale),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border.all(color: borderColor, width: 1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 150,
                            child: AllocationRingChart(
                              data: categorySpends,
                              centerText: state.formatAmount(state.monthlyExpense),
                              centerSubtext: AppLocalizations.translate('bg_spent', locale),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categorySpends.entries.take(4).map((entry) {
                              final double percent = state.monthlyExpense > 0 
                                  ? (entry.value / state.monthlyExpense) * 100 
                                  : 0;
                              final color = AppColors.getCategoryColor(entry.key, dynamicCategories: state.categories);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${percent.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: mutedTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recent Transactions List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.translate('db_recent_activity', locale),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: onNavigateToLedger,
                      child: Row(
                        children: [
                          Text(
                            AppLocalizations.translate('tr_all', locale),
                            style: const TextStyle(
                              color: AppColors.violet,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.violet, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecentTransactionsList(state, locale, cardColor, borderColor, textColor, mutedTextColor),

                // Sponsor Banner Ad at the bottom of the dashboard
                const SponsorBannerAd(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBanner(BuildContext context, AppState state, String locale, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withOpacity(0.18),
            AppColors.rose.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.amber.withOpacity(0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.translate('rm_banner_title', locale),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.translate('rm_banner_body', locale),
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onNavigateToLedger,
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.translate('tr_add_transaction', locale),
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.amber, size: 14),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext context, String balance, String cash, String portfolio, String locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.violet.withOpacity(0.85),
            const Color(0xFF6366F1).withOpacity(0.9), // Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.translate('db_net_worth', locale).toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.translate('db_cash_reserves', locale),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cash,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.translate('db_portfolio_value', locale),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      portfolio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFlowHighlightCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(AppState state, String locale, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    final recent = state.transactions.take(3).toList();

    if (recent.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            AppLocalizations.translate('db_no_recent_transactions', locale),
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (context, index) => Divider(color: borderColor.withOpacity(0.6), height: 1),
        itemBuilder: (context, index) {
          final tx = recent[index];
          final isExpense = tx.type == TransactionType.expense;
          final color = isExpense ? AppColors.rose : AppColors.emerald;
          final String prefix = isExpense ? '-' : '+';
          final categoryColor = AppColors.getCategoryColor(tx.category, dynamicCategories: state.categories);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
                color: categoryColor,
                size: 20,
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
              '$prefix${state.formatAmount(tx.amount)}',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, AppState state, String locale, bool isDark, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String reminderTimeStr = '${state.reminderHour.toString().padLeft(2, '0')}:${state.reminderMinute.toString().padLeft(2, '0')}';
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 28.0,
                    right: 28.0,
                    top: 28.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 28.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.translate('ui_settings', locale),
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

                      // ── CURRENCY ──────────────────────────────────────────
                      _settingsSectionHeader(locale == 'en' ? 'Currency & Region' : 'Tiền tệ & Khu vực', textColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            locale == 'en' ? 'App Currency' : 'Đơn vị tiền tệ',
                            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: state.selectedCurrency,
                                dropdownColor: cardColor,
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.violet),
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                                items: ['USD', 'VND', 'EUR', 'JPY', 'GBP', 'SGD'].map((String val) {
                                  return DropdownMenuItem<String>(
                                    value: val,
                                    child: Text(val),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      state.setCurrency(val);
                                    });
                                  }
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── APPEARANCE ────────────────────────────────────────
                      _settingsSectionHeader(locale == 'en' ? 'Appearance & Themes' : 'Giao diện & Chủ đề', textColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _themeButton('dark', '🌙 Slate Dark', state, setModalState, isDark, cardColor, borderColor, textColor),
                          const SizedBox(width: 8),
                          _themeButton('light', '☀️ Cream Light', state, setModalState, isDark, cardColor, borderColor, textColor),
                          const SizedBox(width: 8),
                          _themeButton('gold', '✨ Vibrant Gold', state, setModalState, isDark, cardColor, borderColor, textColor,
                              locked: !state.isGoldThemeUnlocked),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── NOTIFICATIONS ─────────────────────────────────────
                      _settingsSectionHeader(locale == 'en' ? 'Daily Reminders' : 'Nhắc nhở hàng ngày', textColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.translate('rm_enable_reminder', locale),
                            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          Switch.adaptive(
                            value: state.remindersEnabled,
                            activeColor: AppColors.violet,
                            onChanged: (val) {
                              setModalState(() {
                                state.setReminderSettings(val, state.reminderHour, state.reminderMinute);
                              });
                            },
                          )
                        ],
                      ),
                      if (state.remindersEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.translate('rm_reminder_time', locale),
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final TimeOfDay? time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.violet,
                                          onPrimary: Colors.white,
                                          surface: cardColor,
                                          onSurface: textColor,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setModalState(() {
                                    state.setReminderSettings(true, time.hour, time.minute);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      reminderTimeStr,
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.access_time_rounded, color: AppColors.violet, size: 16),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            state.triggerTestNotification();
                          },
                          child: Text(
                            AppLocalizations.translate('rm_trigger_mock', locale),
                            style: const TextStyle(color: AppColors.violet, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── ADVERTISEMENTS ────────────────────────────────────
                      _settingsSectionHeader(locale == 'en' ? 'Advertisement Settings' : 'Cài đặt quảng cáo', textColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale == 'en' ? 'Show Sponsor Ads' : 'Hiển thị quảng cáo',
                                style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                locale == 'en' ? 'Banner and interstitial ads' : 'Quảng cáo banner và toàn màn hình',
                                style: TextStyle(color: mutedTextColor, fontSize: 11),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: state.adsEnabled,
                            activeColor: const Color(0xFFF59E0B),
                            onChanged: (val) => setModalState(() => state.setAdsEnabled(val)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                          label: Text(
                            locale == 'en' ? 'Demo Interstitial Ad' : 'Xem thử quảng cáo toàn màn hình',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                VibrantInterstitialAd.show(context, () {});
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── OTA UPDATE CENTER ─────────────────────────────────
                      _buildOTAUpdateCenter(context, state, locale, isDark, cardColor, borderColor, textColor, mutedTextColor, setModalState),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _settingsSectionHeader(String label, Color textColor) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: textColor.withOpacity(0.15), thickness: 1)),
      ],
    );
  }

  Widget _themeButton(String name, String label, AppState state, StateSetter setModalState,
      bool isDark, Color cardColor, Color borderColor, Color textColor, {bool locked = false}) {
    final bool isActive = state.themeName == name;
    final Color accent = name == 'gold'
        ? const Color(0xFFF59E0B)
        : name == 'light'
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF6366F1);
    return Expanded(
      child: GestureDetector(
        onTap: locked
            ? null
            : () => setModalState(() => state.setThemeName(name)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? accent.withOpacity(0.15) : cardColor,
            border: Border.all(
              color: isActive ? accent : borderColor,
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked)
                const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF94A3B8))
              else
                Icon(Icons.circle, size: 10, color: isActive ? accent : Colors.transparent),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? accent : textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTAUpdateCenter(BuildContext context, AppState state, String locale,
      bool isDark, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor,
      StateSetter setModalState) {
    final Color goldAccent = const Color(0xFFF59E0B);
    final bool hasUpdate = state.updateAvailable;
    final bool isDownloading = state.isDownloadingUpdate;
    final bool success = state.updateSuccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsSectionHeader(locale == 'en' ? 'Update Center' : 'Trung tâm cập nhật', textColor),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(
              color: success ? goldAccent.withOpacity(0.5) : borderColor,
              width: success ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'en' ? 'Current Version' : 'Phiên bản hiện tại',
                        style: TextStyle(color: mutedTextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vibrant Finance  v${state.currentVersion}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (success)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: goldAccent.withOpacity(0.15),
                        border: Border.all(color: goldAccent.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            locale == 'en' ? 'Up to date!' : 'Mới nhất!',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else if (hasUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.12),
                        border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        locale == 'en' ? '🚀 Update Available!' : '🚀 Có bản cập nhật!',
                        style: const TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),

              // Release notes (shown when update detected)
              if (hasUpdate && state.updateReleaseNotes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  locale == 'en' ? 'What\'s new in v${state.latestVersion}:' : 'Có gì mới trong v${state.latestVersion}:',
                  style: TextStyle(color: mutedTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.06),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.updateReleaseNotes.replaceAll('\\n', '\n'),
                    style: TextStyle(color: textColor, fontSize: 12, height: 1.5),
                  ),
                ),
              ],

              // Download Progress
              if (isDownloading) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.download_rounded, color: AppColors.violet, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      locale == 'en'
                          ? 'Downloading update... ${(state.downloadProgress * 100).toInt()}%'
                          : 'Đang tải xuống... ${(state.downloadProgress * 100).toInt()}%',
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: state.downloadProgress,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    color: AppColors.violet,
                    minHeight: 6,
                  ),
                ),
              ],

              // Gold theme unlock trophy
              if (success) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [goldAccent.withOpacity(0.12), goldAccent.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: goldAccent.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale == 'en' ? 'Vibrant Gold Unlocked!' : 'Đã mở khóa Vibrant Gold!',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              locale == 'en'
                                  ? 'Switch to the Gold theme in Appearance above!'
                                  : 'Chọn chủ đề Gold trong phần Giao diện phía trên!',
                              style: TextStyle(color: mutedTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Action buttons row
              if (!isDownloading)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.refresh_rounded, color: textColor, size: 16),
                        label: Text(
                          locale == 'en' ? 'Check' : 'Kiểm tra',
                          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => setModalState(() {
                          state.checkOTAUpdates();
                        }),
                      ),
                    ),
                    if (hasUpdate) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                          label: Text(
                            locale == 'en' ? 'Update Now' : 'Cập nhật ngay',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setModalState(() {});
                            state.executeOTAUpdate(() {
                              setModalState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    locale == 'en'
                                        ? '🚀 Vibrant Update v${state.currentVersion} installed! Gold Theme unlocked!'
                                        : '🚀 Đã cài đặt phiên bản v${state.currentVersion}! Mở khóa Gold Theme!',
                                  ),
                                  backgroundColor: const Color(0xFFF59E0B),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
