class User {
  final int id;
  final String username;
  final String email;
  final int points;
  final int level;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.points,
    required this.level,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
      level: json['level'] as int? ?? 0,
    );
  }
}
