import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageData {
  final List<dynamic> transactionsJson;
  final List<dynamic> budgetsJson;
  final List<dynamic> assetsJson;
  final List<dynamic> investTransactionsJson;
  final double cashReserves;
  final String locale;
  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;
  
  // New Phase 2 Expansion Fields
  final String selectedCurrency;
  final Map<String, double> exchangeRates;
  final List<dynamic> categoriesJson;
  final String themeMode;

  // New Phase 3 Ads & OTA Fields
  final bool adsEnabled;
  final bool isGoldThemeUnlocked;
  final String currentVersion;

  StorageData({
    required this.transactionsJson,
    required this.budgetsJson,
    required this.assetsJson,
    required this.investTransactionsJson,
    required this.cashReserves,
    required this.locale,
    required this.remindersEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.selectedCurrency,
    required this.exchangeRates,
    required this.categoriesJson,
    required this.themeMode,
    required this.adsEnabled,
    required this.isGoldThemeUnlocked,
    required this.currentVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactionsJson,
      'budgets': budgetsJson,
      'assets': assetsJson,
      'investTransactions': investTransactionsJson,
      'cashReserves': cashReserves,
      'locale': locale,
      'remindersEnabled': remindersEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'selectedCurrency': selectedCurrency,
      'exchangeRates': exchangeRates,
      'categories': categoriesJson,
      'themeMode': themeMode,
      'adsEnabled': adsEnabled,
      'isGoldThemeUnlocked': isGoldThemeUnlocked,
      'currentVersion': currentVersion,
    };
  }

  factory StorageData.fromJson(Map<String, dynamic> json) {
    // Graceful parsing of exchangeRates map
    final Map<String, double> rates = {};
    if (json['exchangeRates'] != null) {
      final rawRates = json['exchangeRates'] as Map<String, dynamic>;
      rawRates.forEach((k, v) {
        rates[k] = (v as num).toDouble();
      });
    }

    return StorageData(
      transactionsJson: json['transactions'] as List<dynamic>? ?? [],
      budgetsJson: json['budgets'] as List<dynamic>? ?? [],
      assetsJson: json['assets'] as List<dynamic>? ?? [],
      investTransactionsJson: json['investTransactions'] as List<dynamic>? ?? [],
      cashReserves: (json['cashReserves'] as num? ?? 50000.0).toDouble(),
      locale: json['locale'] as String? ?? 'en',
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      selectedCurrency: json['selectedCurrency'] as String? ?? 'USD',
      exchangeRates: rates,
      categoriesJson: json['categories'] as List<dynamic>? ?? [],
      themeMode: json['themeMode'] as String? ?? 'ThemeMode.dark',
      adsEnabled: json['adsEnabled'] as bool? ?? true,
      isGoldThemeUnlocked: json['isGoldThemeUnlocked'] as bool? ?? false,
      currentVersion: json['currentVersion'] as String? ?? '1.0.0+1',
    );
  }
}

class StorageService {
  static const String _fileName = 'finance_tracker_data.json';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<StorageData?> loadData() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return null;
      }
      final contents = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(contents);
      return StorageData.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveData(StorageData data) async {
    try {
      final file = await _getLocalFile();
      final jsonString = json.encode(data.toJson());
      await file.writeAsString(jsonString);
    } catch (_) {}
  }
}
