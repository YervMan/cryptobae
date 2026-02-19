class DailyRoast {
  final String id;
  final String roast;
  final int vibeScore;

  DailyRoast({
    required this.id,
    required this.roast,
    required this.vibeScore,
  });

  factory DailyRoast.fromMap(Map<String, dynamic> map) {
    return DailyRoast(
      id: map['id'] ?? '',
      roast: map['roast'] ?? '',
      vibeScore: map['vibe_score'] ?? 50,
    );
  }
}
