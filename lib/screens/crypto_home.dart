import 'package:flutter/material.dart';
import '../models/crypto_coin.dart';
import '../services/coingecko_service.dart';

class CryptoHome extends StatefulWidget {
  const CryptoHome({super.key});

  @override
  State<CryptoHome> createState() => _CryptoHomeState();
}

class _CryptoHomeState extends State<CryptoHome> {
  final service = CoinGeckoService();
  late Future<List<CryptoCoin>> futureCoins;

  @override
  void initState() {
    super.initState();
    futureCoins = service.fetchTopCoins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crypto Bae')),
      body: FutureBuilder<List<CryptoCoin>>(
        future: futureCoins,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Market data unavailable 💔'),
            );
          }

          final coins = snapshot.data!;

          return ListView.builder(
            itemCount: coins.length,
            itemBuilder: (context, index) {
              final coin = coins[index];

              return ListTile(
                title: Text('${coin.name} (${coin.symbol.toUpperCase()})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price: €${coin.price}'),
                    Text('24h %: ${coin.change24h.toStringAsFixed(2)}%'),
                    Text('ATH: €${coin.ath}'),
                    Text(
                        'ATH Distance: ${coin.athChangePercent.toStringAsFixed(2)}%'),
                    Text('24h Volume: €${coin.volume24h}'),
                  ],
                ),
                trailing: coin.marketRank > 0
                    ? Text('#${coin.marketRank}')
                    : const Text('-'),
              );
            },
          );
        },
      ),
    );
  }
}
