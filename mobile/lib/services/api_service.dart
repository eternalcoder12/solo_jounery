import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/leaderboard_entry.dart';
import '../models/points_history.dart';
import '../models/redemption.dart';
import '../models/reward.dart';
import '../models/trip.dart';
import '../models/user.dart';
import '../models/user_profile.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://localhost:8080/api/v1';

  final http.Client _client;
  final String baseUrl;
  String? _token;

  void updateToken(String? token) => _token = token;

  Map<String, String> _headers({bool authenticated = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    _ensureSuccess(response);
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<(String, User)> login({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    updateToken(token);
    return (token, user);
  }

  Future<List<Trip>> fetchTrips({int limit = 20}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/trips?limit=$limit'),
      headers: _headers(),
    );
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trip> createTrip({
    required String title,
    required String description,
    required String location,
    required DateTime visitedAt,
    required List<Map<String, dynamic>> media,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/trips'),
      headers: _headers(authenticated: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'visited_at': visitedAt.toUtc().toIso8601String(),
        'media': media,
      }),
    );
    _ensureSuccess(response);
    return Trip.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 10}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/leaderboard?limit=$limit'),
      headers: _headers(),
    );
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reward>> fetchRewards() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/rewards'),
      headers: _headers(),
    );
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Redemption>> fetchRedemptions({int limit = 20}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me/redemptions?limit=$limit'),
      headers: _headers(authenticated: true),
    );
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Redemption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PointsHistory>> fetchPointsHistory({int limit = 20}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me/history?limit=$limit'),
      headers: _headers(authenticated: true),
    );
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => PointsHistory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserProfile> fetchProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers(authenticated: true),
    );
    _ensureSuccess(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<(Redemption, User)> redeemReward(int rewardId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/rewards/redeem'),
      headers: _headers(authenticated: true),
      body: jsonEncode({'reward_id': rewardId}),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final redemption = Redemption.fromJson(data['redemption'] as Map<String, dynamic>);
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    updateToken(_token);
    return (redemption, user);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        response.body.isEmpty ? 'Unexpected error' : response.body,
      );
    }
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
