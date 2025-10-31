import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'profile_manager.dart';

const _leaderboardSeasonKey = 'current_season_id';
const _leaderboardDataKey = 'seasonal_leaderboard_v1';

class LeaderboardRepository {
  LeaderboardRepository(this._prefs);

  final SharedPreferences _prefs;

  String get currentSeasonId =>
      _prefs.getString(_leaderboardSeasonKey) ?? 'season_001';

  Future<void> setSeasonId(String seasonId) async {
    await _prefs.setString(_leaderboardSeasonKey, seasonId);
  }

  List<LeaderboardEntry> loadSeasonLeaderboard(String seasonId) {
    final jsonString = _prefs.getString('$_leaderboardDataKey:$seasonId');
    if (jsonString == null) return const [];
    final decoded = json.decode(jsonString) as List<dynamic>;
    return decoded
        .map((entry) =>
            LeaderboardEntry.fromJson((entry as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveSeasonLeaderboard(
    String seasonId,
    List<LeaderboardEntry> entries,
  ) async {
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString('$_leaderboardDataKey:$seasonId', jsonString);
  }
}

abstract class CloudSyncService {
  Future<void> syncProfile(PlayerProfile profile);

  Future<void> syncLeaderboard(
    String seasonId,
    List<LeaderboardEntry> entries,
  );
}

class StubCloudSyncService implements CloudSyncService {
  @override
  Future<void> syncProfile(PlayerProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> syncLeaderboard(
    String seasonId,
    List<LeaderboardEntry> entries,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
