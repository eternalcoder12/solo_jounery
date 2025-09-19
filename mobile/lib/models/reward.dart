class Reward {
  final int id;
  final String name;
  final String description;
  final int pointsCost;
  final int inventory;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.inventory,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pointsCost: (json['points_cost'] as num?)?.toInt() ?? 0,
      inventory: json['inventory'] as int? ?? 0,
    );
  }
}
