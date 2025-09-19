import 'points_history.dart';
import 'redemption.dart';
import 'trip.dart';
import 'user.dart';

class UserProfile {
  final User user;
  final int nextLevel;
  final int pointsToNext;
  final int currentLevelFloor;
  final int nextLevelThreshold;
  final int totalTrips;
  final int totalRedemptions;
  final double averageScore;
  final List<PointsHistory> recentHistory;
  final List<Redemption> recentRedemptions;
  final List<Trip> recentTrips;

  UserProfile({
    required this.user,
    required this.nextLevel,
    required this.pointsToNext,
    required this.currentLevelFloor,
    required this.nextLevelThreshold,
    required this.totalTrips,
    required this.totalRedemptions,
    required this.averageScore,
    required this.recentHistory,
    required this.recentRedemptions,
    required this.recentTrips,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      nextLevel: json['next_level'] as int? ?? 0,
      pointsToNext: (json['points_to_next'] as num?)?.toInt() ?? 0,
      currentLevelFloor: (json['current_level_floor'] as num?)?.toInt() ?? 0,
      nextLevelThreshold: (json['next_level_threshold'] as num?)?.toInt() ?? 0,
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      totalRedemptions: (json['total_redemptions'] as num?)?.toInt() ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
      recentHistory: (json['recent_history'] as List<dynamic>? ?? [])
          .map((item) => PointsHistory.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentRedemptions: (json['recent_redemptions'] as List<dynamic>? ?? [])
          .map((item) => Redemption.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentTrips: (json['recent_trips'] as List<dynamic>? ?? [])
          .map((item) => Trip.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
