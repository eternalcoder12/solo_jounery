class LeaderboardEntry {
  final int userId;
  final int points;

  LeaderboardEntry({required this.userId, required this.points});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as int,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}
