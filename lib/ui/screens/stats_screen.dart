import 'package:flutter/material.dart';
import '../../models.dart';
import '../../localization.dart';
import '../../state/app_state.dart';
import '../widgets/custom_charts.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _timeframe = 'week'; // 'week', 'month'

  // Helper to get formatted day abbreviation
  String _getDayAbbreviation(DateTime date, String locale) {
    final List<String> enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> viDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final int idx = date.weekday - 1;
    return locale == 'en' ? enDays[idx] : viDays[idx];
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark;
    final now = DateTime.now();

    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    // 1. Timeframe Filter Logic
    final DateTime limitDate = _timeframe == 'week' 
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month, 1);

    final periodTransactions = state.transactions
        .where((t) => t.dateTime.isAfter(limitDate))
        .toList();

    // 2. Allocation Ring Data Calculation (Expenses only)
    final Map<String, double> categoryAllocation = {};
    double totalExpense = 0.0;
    
    for (var t in periodTransactions) {
      if (t.type == TransactionType.expense) {
        categoryAllocation[t.category] = (categoryAllocation[t.category] ?? 0.0) + t.amount;
        totalExpense += t.amount;
      }
    }

    // Sort category allocation legends (Highest spending category floats to the top!)
    final sortedLegends = categoryAllocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Weekly Trend Chart Calculation
    final List<TrendPoint> trendPoints = [];
    final int daysToCalculate = _timeframe == 'week' ? 7 : 14;

    for (int i = daysToCalculate - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final String label = '${_getDayAbbreviation(date, locale)} ${date.day}';

      final double dayIncome = state.transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.dateTime.day == date.day &&
              t.dateTime.month == date.month &&
              t.dateTime.year == date.year)
          .fold(0.0, (sum, t) => sum + t.amount);

      final double dayExpense = state.transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.dateTime.day == date.day &&
              t.dateTime.month == date.month &&
              t.dateTime.year == date.year)
          .fold(0.0, (sum, t) => sum + t.amount);

      trendPoints.add(TrendPoint(label: label, income: dayIncome, expense: dayExpense));
    }

    // Calculate savings rate
    final double periodIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final double periodExpense = totalExpense;
    final double savingsRate = periodIncome > 0 
        ? ((periodIncome - periodExpense) / periodIncome) * 100 
        : 0.0;

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
                // Header Titles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate('st_stats_title', locale),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          locale == 'en' ? 'Visual analytics and expense breakdowns' : 'Phân tích trực quan và phân loại chi tiêu',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Timeframe Selector Chips
                Row(
                  children: [
                    _buildTimeframeChip(
                      label: AppLocalizations.translate('st_timeframe_week', locale),
                      timeframeKey: 'week',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),
                    const SizedBox(width: 10),
                    _buildTimeframeChip(
                      label: AppLocalizations.translate('st_timeframe_month', locale),
                      timeframeKey: 'month',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Summary Stats Metrics (Income, Expense, Savings Rate)
                _buildSummaryPeriodCard(periodIncome, periodExpense, savingsRate, locale, cardColor, borderColor, mutedTextColor),
                const SizedBox(height: 24),

                if (periodTransactions.isEmpty) ...[
                  const SizedBox(height: 40),
                  _buildEmptyState(locale, cardColor, mutedTextColor),
                ] else ...[
                  // Cash Flow Curve Chart (Line Area Chart)
                  Text(
                    AppLocalizations.translate('st_income_vs_expense', locale),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 240,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border.all(color: borderColor, width: 1),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: state.themeMode == ThemeMode.light
                          ? [
                              const BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: TrendAreaChart(points: trendPoints),
                  ),
                  const SizedBox(height: 24),

                  // Allocation Pie Ring Chart
                  if (categoryAllocation.isNotEmpty) ...[
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border.all(color: borderColor, width: 1),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: state.themeMode == ThemeMode.light
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
                        children: [
                          SizedBox(
                            height: 160,
                            child: AllocationRingChart(
                              data: categoryAllocation,
                              centerText: state.formatAmount(totalExpense),
                              centerSubtext: AppLocalizations.translate('st_total_spending', locale),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Auto-sorted Legend table
                          Column(
                            children: sortedLegends.map((entry) {
                              final double percent = totalExpense > 0 
                                  ? (entry.value / totalExpense) * 100 
                                  : 0;
                              final color = AppColors.getCategoryColor(entry.key, dynamicCategories: state.categories);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      state.formatAmount(entry.value),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${percent.toStringAsFixed(1)}%',
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
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeChip({
    required String label,
    required String timeframeKey,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    final bool isActive = _timeframe == timeframeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeframe = timeframeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.violet.withOpacity(0.12) : cardColor,
          border: Border.all(
            color: isActive ? AppColors.violet : borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.violet) : mutedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPeriodCard(
      double income, double expense, double savingsRate, String locale,
      Color cardColor, Color borderColor, Color mutedTextColor) {
    final bool hasSavings = savingsRate >= 0;
    final state = AppStateProvider.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: state.themeMode == ThemeMode.light
            ? [
                const BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetricItem(
            label: AppLocalizations.translate('db_monthly_income', locale),
            value: state.formatAmount(income),
            color: AppColors.emerald,
            mutedTextColor: mutedTextColor,
          ),
          Container(width: 1, height: 40, color: borderColor),
          _buildMetricItem(
            label: AppLocalizations.translate('db_monthly_expense', locale),
            value: state.formatAmount(expense),
            color: AppColors.rose,
            mutedTextColor: mutedTextColor,
          ),
          Container(width: 1, height: 40, color: borderColor),
          _buildMetricItem(
            label: locale == 'en' ? 'Savings Rate' : 'Tỷ lệ tích lũy',
            value: '${hasSavings ? '+' : ''}${savingsRate.toStringAsFixed(0)}%',
            color: hasSavings ? AppColors.violet : AppColors.rose,
            mutedTextColor: mutedTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required Color mutedTextColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: mutedTextColor, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String locale, Color cardColor, Color mutedTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
            child: Icon(Icons.bar_chart_rounded, color: mutedTextColor, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.translate('st_no_data', locale),
            style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
