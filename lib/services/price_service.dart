import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PriceResult {
  final double price;
  final double changePercent;
  final bool isLive;

  PriceResult({
    required this.price,
    required this.changePercent,
    required this.isLive,
  });
}

class PriceService {
  final http.Client _client;
  final Random _random = Random();

  PriceService({http.Client? client}) : _client = client ?? http.Client();

  // Baseline prices to use when we simulate prices offline
  static const Map<String, double> _basePrices = {
    'GC=F': 2350.0,    // Gold Futures
    'SI=F': 28.50,     // Silver Futures
    'AAPL': 185.20,    // Apple
    'TSLA': 175.40,    // Tesla
    'GOOG': 168.30,    // Google
    'BTC-USD': 65200.0, // Bitcoin
    'ETH-USD': 3450.0,  // Ethereum
  };

  /// Fetches real-time price and 24h percent change for a ticker from Yahoo Finance.
  /// If it fails (offline or rate-limited), it falls back to a realistic simulated price.
  Future<PriceResult> getPrice(String ticker, {double? lastKnownPrice}) async {
    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker');
    
    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']?['result']?[0];
        if (result != null) {
          final meta = result['meta'];
          final double? price = (meta['regularMarketPrice'] as num?)?.toDouble();
          final double? prevClose = (meta['chartPreviousClose'] as num?)?.toDouble();

          if (price != null) {
            double changePercent = 0.0;
            if (prevClose != null && prevClose > 0) {
              changePercent = ((price - prevClose) / prevClose) * 100;
            } else if (meta['regularMarketChangePercent'] != null) {
              changePercent = (meta['regularMarketChangePercent'] as num).toDouble();
            }
            return PriceResult(
              price: price,
              changePercent: changePercent,
              isLive: true,
            );
          }
        }
      }
      
      // If response was not 200 or parsing failed, fallback
      return _generateSimulatedPrice(ticker, lastKnownPrice);
    } catch (_) {
      // Catch network timeouts, connection errors, etc. and fallback
      return _generateSimulatedPrice(ticker, lastKnownPrice);
    }
  }

  /// Generates a realistic simulated price change based on last known price or baseline
  PriceResult _generateSimulatedPrice(String ticker, double? lastPrice) {
    final basePrice = lastPrice ?? _basePrices[ticker] ?? 100.0;
    // Simulate a random walk of -1.5% to +1.8%
    final percentChange = (_random.nextDouble() * 3.3) - 1.5;
    final multiplier = 1 + (percentChange / 100);
    final simulatedPrice = basePrice * multiplier;

    return PriceResult(
      price: simulatedPrice,
      changePercent: percentChange,
      isLive: false,
    );
  }

  /// Gets simulated historical price ticks for charting purposes
  List<double> generateSimulatedHistory(String ticker, int points, double currentPrice) {
    final List<double> history = [];
    double price = currentPrice;
    
    // Generate history backwards
    for (int i = 0; i < points; i++) {
      history.insert(0, price);
      // reverse random walk: simulate previous prices
      final change = (_random.nextDouble() * 4.0) - 2.0; // -2% to +2%
      price = price / (1 + (change / 100));
    }
    
    return history;
  }
}
