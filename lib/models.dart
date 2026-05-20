enum TransactionType { expense, income }

enum AssetCategory { stock, crypto, metal }

enum InvestmentType { buy, sell }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime dateTime;
  final String notes;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.dateTime,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      category: json['category'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class Budget {
  final String id;
  final String category;
  final double limitAmount;
  double spentAmount;

  Budget({
    required this.id,
    required this.category,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });

  double get percentage => limitAmount > 0 ? (spentAmount / limitAmount) : 0.0;
  bool get isExceeded => spentAmount > limitAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num? ?? 0.0).toDouble(),
    );
  }
}

class InvestmentAsset {
  final String id;
  final String name;
  final String ticker;
  final AssetCategory category;
  double currentPrice;
  double changePercent;
  List<double> historicalPrices;
  double averageBuyPrice;
  double totalQuantity;

  InvestmentAsset({
    required this.id,
    required this.name,
    required this.ticker,
    required this.category,
    required this.currentPrice,
    this.changePercent = 0.0,
    required this.historicalPrices,
    this.averageBuyPrice = 0.0,
    this.totalQuantity = 0.0,
  });

  double get totalValue => totalQuantity * currentPrice;
  double get totalCost => totalQuantity * averageBuyPrice;
  double get totalProfit => totalValue - totalCost;
  double get profitPercent => totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;
  bool get isOwned => totalQuantity > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ticker': ticker,
      'category': category.name,
      'currentPrice': currentPrice,
      'changePercent': changePercent,
      'historicalPrices': historicalPrices,
      'averageBuyPrice': averageBuyPrice,
      'totalQuantity': totalQuantity,
    };
  }

  factory InvestmentAsset.fromJson(Map<String, dynamic> json) {
    return InvestmentAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      ticker: json['ticker'] as String,
      category: AssetCategory.values.byName(json['category'] as String),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      changePercent: (json['changePercent'] as num? ?? 0.0).toDouble(),
      historicalPrices: (json['historicalPrices'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      averageBuyPrice: (json['averageBuyPrice'] as num? ?? 0.0).toDouble(),
      totalQuantity: (json['totalQuantity'] as num? ?? 0.0).toDouble(),
    );
  }
}

class InvestmentTransaction {
  final String id;
  final String assetTicker;
  final InvestmentType type;
  final double quantity;
  final double pricePerUnit;
  final DateTime dateTime;

  InvestmentTransaction({
    required this.id,
    required this.assetTicker,
    required this.type,
    required this.quantity,
    required this.pricePerUnit,
    required this.dateTime,
  });

  double get totalAmount => quantity * pricePerUnit;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetTicker': assetTicker,
      'type': type.name,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory InvestmentTransaction.fromJson(Map<String, dynamic> json) {
    return InvestmentTransaction(
      id: json['id'] as String,
      assetTicker: json['assetTicker'] as String,
      type: InvestmentType.values.byName(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }
}

class AppCategory {
  final String id;
  final String name;
  final String icon; // Icon name string
  final int colorValue; // Hex color code
  final bool isCustom;
  final bool isIncome;

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.isCustom = false,
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'isCustom': isCustom,
      'isIncome': isIncome,
    };
  }

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorValue: json['colorValue'] as int,
      isCustom: json['isCustom'] as bool? ?? false,
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }
}
