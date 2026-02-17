class CryptoCoin {
  final String id;
  final String name;
  final String symbol;
  final double price;
  final double change24h;
  final double ath;
  final double athChangePercent;
  final int marketRank;
  final double volume24h;

  CryptoCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.ath,
    required this.athChangePercent,
    required this.marketRank,
    required this.volume24h,
  });

  factory CryptoCoin.fromJson(Map<String, dynamic> json) {
    return CryptoCoin(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      price: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      change24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      ath: (json['ath'] as num?)?.toDouble() ?? 0.0,
      athChangePercent:
          (json['ath_change_percentage'] as num?)?.toDouble() ?? 0.0,
      marketRank: json['market_cap_rank'] ?? 0,
      volume24h: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
