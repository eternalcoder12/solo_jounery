import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../models/points_history.dart';
import '../models/redemption.dart';
import '../models/reward.dart';
import '../models/trip.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  AppState({ApiService? apiService}) : api = apiService ?? ApiService();

  final ApiService api;

  User? currentUser;
  List<Trip> trips = const [];
  List<Reward> rewards = const [];
  List<LeaderboardEntry> leaderboard = const [];
  UserProfile? profile;
  List<PointsHistory> history = const [];
  List<Redemption> redemptions = const [];
  bool loading = false;
  bool profileLoading = false;
  bool historyLoading = false;
  bool redemptionsLoading = false;
  bool syncing = false;
  String? error;

  Future<void> register(String username, String email, String password) async {
    try {
      error = null;
      await api.register(username: username, email: email, password: password);
    } on ApiException catch (e) {
      error = e.message;
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.login(email: email, password: password);
      currentUser = result.$2;
      notifyListeners();
      await Future.wait([loadTrips(), loadRewards(), loadLeaderboard(), loadProfile()]);
    } on ApiException catch (e) {
      error = e.message;
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrips() async {
    try {
      trips = await api.fetchTrips();
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadRewards() async {
    try {
      rewards = await api.fetchRewards();
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      leaderboard = await api.fetchLeaderboard();
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> createTrip({
    required String title,
    required String description,
    required String location,
    required DateTime visitedAt,
    required List<Map<String, dynamic>> media,
  }) async {
    error = null;
    try {
      final trip = await api.createTrip(
        title: title,
        description: description,
        location: location,
        visitedAt: visitedAt,
        media: media,
      );
      trips = [trip, ...trips];
      await Future.wait([loadLeaderboard(), loadProfile(), loadPointsHistory(limit: 10)]);
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> redeem(int rewardId) async {
    error = null;
    try {
      await api.redeemReward(rewardId);
      await Future.wait([
        loadRewards(),
        loadLeaderboard(),
        loadProfile(),
        loadRedemptions(limit: 20),
        loadPointsHistory(limit: 10),
      ]);
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadProfile() async {
    if (currentUser == null) return;
    error = null;
    profileLoading = true;
    notifyListeners();
    try {
      final result = await api.fetchProfile();
      profile = result;
      currentUser = result.user;
      history = result.recentHistory;
      redemptions = result.recentRedemptions;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      profileLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPointsHistory({int limit = 30}) async {
    if (currentUser == null) return;
    error = null;
    historyLoading = true;
    notifyListeners();
    try {
      history = await api.fetchPointsHistory(limit: limit);
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRedemptions({int limit = 30}) async {
    if (currentUser == null) return;
    error = null;
    redemptionsLoading = true;
    notifyListeners();
    try {
      redemptions = await api.fetchRedemptions(limit: limit);
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      redemptionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    if (currentUser == null) return;
    error = null;
    syncing = true;
    notifyListeners();
    try {
      await Future.wait([
        loadTrips(),
        loadRewards(),
        loadLeaderboard(),
        loadProfile(),
        loadRedemptions(limit: 20),
      ]);
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}

extension on User {
  User copyWith({int? points, int? level}) {
    return User(
      id: id,
      username: username,
      email: email,
      points: points ?? this.points,
      level: level ?? this.level,
    );
  }
}
