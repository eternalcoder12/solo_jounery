class PointsHistory {
  final int id;
  final DateTime createdAt;
  final int delta;
  final String reason;

  const PointsHistory({
    required this.id,
    required this.createdAt,
    required this.delta,
    required this.reason,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      id: json['id'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
