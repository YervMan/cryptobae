import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_coin.dart';

class CoinGeckoService {
  Future<List<CryptoCoin>> fetchTopCoins() async {
    final uri = Uri.parse(
      'https://api.coingecko.com/api/v3/coins/markets'
      '?vs_currency=eur'
      '&order=market_cap_desc'
      '&per_page=20'
      '&page=1'
      '&price_change_percentage=24h',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => CryptoCoin.fromJson(e)).toList();
      } else {
        throw Exception('API error');
      }
    } catch (e) {
      // Failsafe
      return [];
    }
  }
}
