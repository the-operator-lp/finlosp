import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  // Fallback exchange rates (relative to USD)
  final Map<String, double> fallbackRates = {
    'USD': 1.0,
    'VND': 25400.0,
    'EUR': 0.92,
    'JPY': 156.0,
    'GBP': 0.79,
    'SGD': 1.34,
  };

  /// Fetches exchange rates relative to USD from a high-speed public API.
  /// Automatically falls back to high-fidelity defaults in case of network issues.
  Future<Map<String, double>> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['rates'] != null) {
          final Map<String, dynamic> rawRates = data['rates'] as Map<String, dynamic>;
          final Map<String, double> rates = {};

          // Filter only our supported currencies
          final supported = ['USD', 'VND', 'EUR', 'JPY', 'GBP', 'SGD'];
          for (var currency in supported) {
            if (rawRates.containsKey(currency)) {
              rates[currency] = (rawRates[currency] as num).toDouble();
            } else {
              rates[currency] = fallbackRates[currency]!;
            }
          }
          return rates;
        }
      }
      return fallbackRates;
    } catch (_) {
      // Offline fallback
      return fallbackRates;
    }
  }

  /// Get the correct visual symbol representation for each currency code
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'VND':
        return '₫';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'GBP':
        return '£';
      case 'SGD':
        return 'S\$';
      case 'USD':
      default:
        return '\$';
    }
  }
}
