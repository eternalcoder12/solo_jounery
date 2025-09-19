import 'reward.dart';

class Redemption {
  final int id;
  final DateTime createdAt;
  final String status;
  final Reward? reward;

  Redemption({
    required this.id,
    required this.createdAt,
    required this.status,
    this.reward,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      reward: json['reward'] != null
          ? Reward.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
    );
  }
}
