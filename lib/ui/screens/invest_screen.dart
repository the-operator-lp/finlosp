import 'package:flutter/material.dart';
import '../../models.dart';
import '../../localization.dart';
import '../../state/app_state.dart';
import '../widgets/custom_charts.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _categoryFilter = 'all'; // 'all', 'stock', 'crypto', 'metal'
  String _activeSort = 'ticker';   // 'ticker', 'value', 'profit'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTradeSheet(BuildContext context, AppState state, InvestmentAsset asset, InvestmentType type) {
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final quantityController = TextEditingController();
    String? errorMessage;
    final double price = asset.currentPrice;

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
            final qty = double.tryParse(quantityController.text) ?? 0.0;
            final double totalCost = qty * price;
            
            // Validate real-time trades
            bool isValid = qty > 0;
            if (type == InvestmentType.buy) {
              isValid = isValid && (totalCost <= state.cashReserves);
            } else {
              isValid = isValid && (qty <= asset.totalQuantity);
            }

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
                          type == InvestmentType.buy ? 'iv_buy_shares' : 'iv_sell_shares',
                          locale,
                          params: {'ticker': asset.ticker},
                        ),
                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close_rounded, color: textColor, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Asset info summary row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(asset.ticker, style: TextStyle(color: mutedTextColor, fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              state.formatAmount(price),
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: asset.changePercent >= 0 ? AppColors.emerald : AppColors.rose,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cash Reserves Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.translate('db_cash_reserves', locale),
                        style: TextStyle(color: mutedTextColor, fontSize: 13),
                      ),
                      Text(
                        state.formatAmount(state.cashReserves),
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Owned Shares Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale == 'en' ? 'Owned holdings' : 'Số lượng sở hữu',
                        style: TextStyle(color: mutedTextColor, fontSize: 13),
                      ),
                      Text(
                        '${asset.totalQuantity.toStringAsFixed(4)} ${asset.ticker}',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quantity input
                  Text(
                    AppLocalizations.translate('iv_quantity', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor, fontSize: 16),
                    onChanged: (val) {
                      setModalState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '0.0',
                      hintStyle: TextStyle(color: mutedTextColor),
                      suffixText: asset.ticker,
                      suffixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 20),

                  // Total trade summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale == 'en' ? 'Total trade valuation' : 'Tổng giá trị giao dịch',
                        style: TextStyle(color: mutedTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        state.formatAmount(totalCost),
                        style: TextStyle(
                          color: type == InvestmentType.buy ? AppColors.violet : AppColors.amber,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.rose, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Execute Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type == InvestmentType.buy ? AppColors.violet : AppColors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: !isValid ? null : () {
                        bool success = false;
                        if (type == InvestmentType.buy) {
                          success = state.buyAsset(asset.ticker, qty);
                          if (!success) {
                            setModalState(() {
                              errorMessage = AppLocalizations.translate('iv_insufficient_cash', locale);
                            });
                          }
                        } else {
                          success = state.sellAsset(asset.ticker, qty);
                          if (!success) {
                            setModalState(() {
                              errorMessage = AppLocalizations.translate('iv_insufficient_shares', locale);
                            });
                          }
                        }

                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.translate('iv_trade_success', locale)),
                              backgroundColor: AppColors.emerald,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        AppLocalizations.translate(
                          type == InvestmentType.buy ? 'iv_buy' : 'iv_sell',
                          locale,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
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

    // Calculate Portfolio Unrealized P&L
    double totalCost = 0.0;
    double totalValue = 0.0;
    for (var asset in state.assets) {
      if (asset.isOwned) {
        totalCost += asset.totalCost;
        totalValue += asset.totalValue;
      }
    }
    double totalPnL = totalValue - totalCost;
    double pnlPercent = totalCost > 0 ? (totalPnL / totalCost) * 100 : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header Title & API refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.translate('iv_invest_title', locale),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        locale == 'en' ? 'Simulated live trading portfolio' : 'Danh mục đầu tư giả lập thời gian thực',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Refresh Prices Icon with interactive state spinner
                  GestureDetector(
                    onTap: state.isLoading ? null : state.refreshPrices,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.violet),
                              ),
                            )
                          : Icon(Icons.refresh_rounded, color: textColor, size: 20),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 18),

              // Dynamic live/simulated price badge
              _buildPriceSourceBadge(state, locale),
              const SizedBox(height: 16),

              // Wallet Reserves & Portfolio performance
              _buildPortfolioPerformanceCard(state, totalValue, totalPnL, pnlPercent, locale, cardColor, borderColor, textColor, mutedTextColor),
              const SizedBox(height: 20),

              // TabBar selectors: My Portfolio vs Market
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.violet,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: mutedTextColor,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: AppLocalizations.translate('iv_holdings', locale)),
                    Tab(text: AppLocalizations.translate('iv_market', locale)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Asset Category Filters & search ticker searchbar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor, fontSize: 12),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: AppLocalizations.translate('iv_search_asset', locale),
                          hintStyle: TextStyle(color: mutedTextColor, fontSize: 12),
                          prefixIcon: Icon(Icons.search_rounded, color: mutedTextColor, size: 16),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _categoryFilter,
                    dropdownColor: cardColor,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.filter_list_rounded, color: AppColors.violet, size: 20),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(locale == 'en' ? 'All Categories' : 'Tất cả', style: TextStyle(color: textColor, fontSize: 12))),
                      DropdownMenuItem(value: 'stock', child: Text(locale == 'en' ? 'Stocks' : 'Cổ phiếu', style: TextStyle(color: textColor, fontSize: 12))),
                      DropdownMenuItem(value: 'crypto', child: Text(locale == 'en' ? 'Crypto' : 'Tiền điện tử', style: TextStyle(color: textColor, fontSize: 12))),
                      DropdownMenuItem(value: 'metal', child: Text(locale == 'en' ? 'Precious Metals' : 'Kim loại quý', style: TextStyle(color: textColor, fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _categoryFilter = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _activeSort,
                    dropdownColor: cardColor,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort_rounded, color: AppColors.violet, size: 20),
                    items: [
                      DropdownMenuItem(value: 'ticker', child: Text(AppLocalizations.translate('iv_sort_ticker', locale), style: TextStyle(color: textColor, fontSize: 12))),
                      DropdownMenuItem(value: 'value', child: Text(AppLocalizations.translate('iv_sort_value', locale), style: TextStyle(color: textColor, fontSize: 12))),
                      DropdownMenuItem(value: 'profit', child: Text(AppLocalizations.translate('iv_sort_profit', locale), style: TextStyle(color: textColor, fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _activeSort = val;
                        });
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Expanded Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Portfolio holdings
                    _buildPortfolioTab(context, state, locale, totalValue, cardColor, borderColor, textColor, mutedTextColor),
                    // Market assets
                    _buildMarketTab(context, state, locale, cardColor, borderColor, textColor, mutedTextColor),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSourceBadge(AppState state, String locale) {
    final bool isLive = state.isLivePrices;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLive ? AppColors.emerald.withOpacity(0.12) : AppColors.amber.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isLive ? AppColors.emerald : AppColors.amber, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isLive ? AppColors.emerald : AppColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.translate(isLive ? 'iv_api_live' : 'iv_api_sim', locale),
                style: TextStyle(
                  color: isLive ? AppColors.emerald : AppColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioPerformanceCard(
      AppState state, double totalValue, double profit, double pct, String locale,
      Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    final bool isPositive = profit >= 0;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.translate('iv_portfolio_performance', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.formatAmount(totalValue),
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.translate('iv_unrealized_profit', locale),
                    style: TextStyle(color: mutedTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: isPositive ? AppColors.emerald : AppColors.rose,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${pct.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? AppColors.emerald : AppColors.rose,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),
          // Sub wallet cash balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.translate('db_cash_reserves', locale),
                style: TextStyle(color: mutedTextColor, fontSize: 12),
              ),
              Text(
                state.formatAmount(state.cashReserves),
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(BuildContext context, AppState state, String locale, double totalHoldingsVal,
      Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    List<InvestmentAsset> owned = state.assets.where((a) => a.isOwned).toList();

    // Filter categories
    owned = _filterAssetsByCategory(owned);
    // Search text filter
    owned = _filterAssetsBySearch(owned);
    // Sort
    owned = _sortAssets(owned);

    if (owned.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
              child: Icon(Icons.wallet_rounded, color: mutedTextColor, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.translate('iv_empty_holdings', locale),
              style: TextStyle(color: mutedTextColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: owned.length,
      itemBuilder: (context, index) {
        final asset = owned[index];
        return _buildOwnedAssetCard(context, state, asset, locale, cardColor, borderColor, textColor, mutedTextColor);
      },
    );
  }

  Widget _buildMarketTab(BuildContext context, AppState state, String locale,
      Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    List<InvestmentAsset> allAssets = List.from(state.assets);

    // Filters
    allAssets = _filterAssetsByCategory(allAssets);
    allAssets = _filterAssetsBySearch(allAssets);
    // Sort
    allAssets = _sortAssets(allAssets);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: allAssets.length,
      itemBuilder: (context, index) {
        final asset = allAssets[index];
        return _buildMarketAssetCard(context, state, asset, locale, cardColor, borderColor, textColor, mutedTextColor);
      },
    );
  }

  List<InvestmentAsset> _filterAssetsByCategory(List<InvestmentAsset> list) {
    if (_categoryFilter == 'all') return list;
    final catMap = {
      'stock': AssetCategory.stock,
      'crypto': AssetCategory.crypto,
      'metal': AssetCategory.metal,
    };
    return list.where((a) => a.category == catMap[_categoryFilter]).toList();
  }

  List<InvestmentAsset> _filterAssetsBySearch(List<InvestmentAsset> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((a) => a.ticker.toLowerCase().contains(q) || a.name.toLowerCase().contains(q)).toList();
  }

  List<InvestmentAsset> _sortAssets(List<InvestmentAsset> list) {
    final sorted = List<InvestmentAsset>.from(list);
    if (_activeSort == 'ticker') {
      sorted.sort((a, b) => a.ticker.compareTo(b.ticker));
    } else if (_activeSort == 'value') {
      sorted.sort((a, b) {
        final double valA = a.isOwned ? a.totalValue : a.currentPrice;
        final double valB = b.isOwned ? b.totalValue : b.currentPrice;
        return valB.compareTo(valA);
      });
    } else if (_activeSort == 'profit') {
      sorted.sort((a, b) {
        final double profitA = a.isOwned ? a.profitPercent : a.changePercent;
        final double profitB = b.isOwned ? b.profitPercent : b.changePercent;
        return profitB.compareTo(profitA);
      });
    }
    return sorted;
  }

  Widget _buildOwnedAssetCard(BuildContext context, AppState state, InvestmentAsset asset, String locale,
      Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    final double profit = asset.totalProfit;
    final bool isPositive = profit >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(asset.ticker, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.getCategoryColor(asset.category.name).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          asset.category.name.toUpperCase(),
                          style: TextStyle(color: AppColors.getCategoryColor(asset.category.name), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${asset.totalQuantity.toStringAsFixed(4)} units', style: TextStyle(color: mutedTextColor, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.formatAmount(asset.totalValue),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isPositive ? AppColors.emerald : AppColors.rose, size: 16),
                      Text(
                        '${asset.profitPercent.toStringAsFixed(2)}%',
                        style: TextStyle(color: isPositive ? AppColors.emerald : AppColors.rose, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(backgroundColor: AppColors.violet.withOpacity(0.12)),
                  child: Text(AppLocalizations.translate('iv_buy', locale), style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.bold)),
                  onPressed: () => _showTradeSheet(context, state, asset, InvestmentType.buy),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(backgroundColor: AppColors.amber.withOpacity(0.12)),
                  child: Text(AppLocalizations.translate('iv_sell', locale), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
                  onPressed: () => _showTradeSheet(context, state, asset, InvestmentType.sell),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMarketAssetCard(BuildContext context, AppState state, InvestmentAsset asset, String locale,
      Color cardColor, Color borderColor, Color textColor, Color mutedTextColor) {
    final double price = asset.currentPrice;
    final double change = asset.changePercent;
    final bool isPositive = change >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getCategoryColor(asset.category.name).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    asset.category == AssetCategory.stock
                        ? Icons.trending_up_rounded
                        : asset.category == AssetCategory.crypto
                            ? Icons.currency_bitcoin_rounded
                            : Icons.diamond_rounded,
                    color: AppColors.getCategoryColor(asset.category.name),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(asset.ticker, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                          if (asset.isOwned) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: const Text('OWNED', style: TextStyle(color: AppColors.emerald, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(asset.name, style: TextStyle(color: mutedTextColor, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(state.formatAmount(price), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(color: isPositive ? AppColors.emerald : AppColors.rose, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _showTradeSheet(context, state, asset, InvestmentType.buy),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.violet, borderRadius: BorderRadius.circular(10)),
                  child: Text(AppLocalizations.translate('iv_buy', locale), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
