import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/missions.dart';
import '../model/theme_skin.dart';

const _profileStorageKey = 'player_profile_v1';

class LeaderboardEntry {
  LeaderboardEntry({
    required this.score,
    required this.durationSeconds,
    required this.timestamp,
    required this.seasonId,
  });

  final int score;
  final int durationSeconds;
  final DateTime timestamp;
  final String seasonId;

  Map<String, dynamic> toJson() => {
        'score': score,
        'duration': durationSeconds,
        'timestamp': timestamp.toIso8601String(),
        'season': seasonId,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      score: json['score'] as int? ?? 0,
      durationSeconds: json['duration'] as int? ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      seasonId: json['season'] as String? ?? 'default',
    );
  }
}

class PlayerProfile {
  PlayerProfile({
    required this.highScore,
    required this.totalScore,
    required this.unlockedThemes,
    required this.activeThemeId,
    required this.leaderboard,
    required this.practiceCompleted,
    required this.onboardingSeen,
    required this.missionCompletions,
  });

  final int highScore;
  final int totalScore;
  final Set<String> unlockedThemes;
  final String activeThemeId;
  final List<LeaderboardEntry> leaderboard;
  final bool practiceCompleted;
  final bool onboardingSeen;
  final Map<String, int> missionCompletions;

  PlayerProfile copyWith({
    int? highScore,
    int? totalScore,
    Set<String>? unlockedThemes,
    String? activeThemeId,
    List<LeaderboardEntry>? leaderboard,
    bool? practiceCompleted,
    bool? onboardingSeen,
    Map<String, int>? missionCompletions,
  }) {
    return PlayerProfile(
      highScore: highScore ?? this.highScore,
      totalScore: totalScore ?? this.totalScore,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      activeThemeId: activeThemeId ?? this.activeThemeId,
      leaderboard: leaderboard ?? this.leaderboard,
      practiceCompleted: practiceCompleted ?? this.practiceCompleted,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      missionCompletions: missionCompletions ?? this.missionCompletions,
    );
  }

  Map<String, dynamic> toJson() => {
        'highScore': highScore,
        'totalScore': totalScore,
        'unlockedThemes': unlockedThemes.toList(),
        'activeThemeId': activeThemeId,
        'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
        'practiceCompleted': practiceCompleted,
        'onboardingSeen': onboardingSeen,
        'missionCompletions': missionCompletions,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final unlocked = <String>{...(json['unlockedThemes'] as List?)?.cast<String>() ?? {}};
    return PlayerProfile(
      highScore: json['highScore'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      unlockedThemes: unlocked,
      activeThemeId: json['activeThemeId'] as String? ?? builtInThemes.first.id,
      leaderboard: (json['leaderboard'] as List?)
              ?.map((entry) =>
                  LeaderboardEntry.fromJson((entry as Map).cast<String, dynamic>()))
              .toList() ??
          const <LeaderboardEntry>[],
      practiceCompleted: json['practiceCompleted'] as bool? ?? false,
      onboardingSeen: json['onboardingSeen'] as bool? ?? false,
      missionCompletions:
          (json['missionCompletions'] as Map?)?.cast<String, int>() ?? {},
    );
  }

  static PlayerProfile createDefault() => PlayerProfile(
        highScore: 0,
        totalScore: 0,
        unlockedThemes: {builtInThemes.first.id},
        activeThemeId: builtInThemes.first.id,
        leaderboard: const [],
        practiceCompleted: false,
        onboardingSeen: false,
        missionCompletions: const {},
      );
}

class ProfileManager extends ChangeNotifier {
  ProfileManager(this._prefs, this._profile);

  final SharedPreferences _prefs;
  PlayerProfile _profile;
  PlayerProfile get profile => _profile;

  ThemeSkin get activeTheme =>
      builtInThemes.firstWhere(
        (skin) => skin.id == _profile.activeThemeId,
        orElse: () => builtInThemes.first,
      );

  static Future<ProfileManager> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileStorageKey);
    final profile = jsonString == null
        ? PlayerProfile.createDefault()
        : PlayerProfile.fromJson(
            json.decode(jsonString) as Map<String, dynamic>,
          );
    return ProfileManager(prefs, profile);
  }

  Future<void> save() async {
    await _prefs.setString(
      _profileStorageKey,
      json.encode(_profile.toJson()),
    );
  }

  void recordMissionCompletion(String missionId) {
    final completions = Map<String, int>.from(_profile.missionCompletions);
    completions[missionId] = (completions[missionId] ?? 0) + 1;
    _profile = _profile.copyWith(missionCompletions: completions);
    _updateUnlocksForMission(missionId);
    notifyListeners();
    save();
  }

  void recordRun({
    required int score,
    required int durationSeconds,
    required bool practiceMode,
    String seasonId = 'season_001',
  }) {
    if (practiceMode) {
      _profile = _profile.copyWith(practiceCompleted: true);
    }
    var highScore = _profile.highScore;
    if (!practiceMode && score > highScore) {
      highScore = score;
    }
    var totalScore = _profile.totalScore;
    if (!practiceMode) {
      totalScore += score;
    }
    final unlocked = Set<String>.from(_profile.unlockedThemes);
    unlocked.add(builtInThemes.first.id);
    for (final skin in builtInThemes) {
      if (skin.unlockType == ThemeUnlockType.score &&
          score >= int.tryParse(skin.unlockValue ?? '')!) {
        unlocked.add(skin.id);
      }
    }

    final leaderboard = List<LeaderboardEntry>.from(_profile.leaderboard);
    if (!practiceMode) {
      leaderboard.add(
        LeaderboardEntry(
          score: score,
          durationSeconds: durationSeconds,
          timestamp: DateTime.now(),
          seasonId: seasonId,
        ),
      );
      leaderboard.sort((a, b) => b.score.compareTo(a.score));
      if (leaderboard.length > 25) {
        leaderboard.removeRange(25, leaderboard.length);
      }
    }

    _profile = _profile.copyWith(
      highScore: highScore,
      totalScore: totalScore,
      unlockedThemes: unlocked,
      leaderboard: leaderboard,
    );
    notifyListeners();
    save();
  }

  void selectTheme(String themeId) {
    if (!_profile.unlockedThemes.contains(themeId)) {
      return;
    }
    _profile = _profile.copyWith(activeThemeId: themeId);
    notifyListeners();
    save();
  }

  void markOnboardingSeen() {
    if (_profile.onboardingSeen) return;
    _profile = _profile.copyWith(onboardingSeen: true);
    notifyListeners();
    save();
  }

  void _updateUnlocksForMission(String missionId) {
    final unlocked = Set<String>.from(_profile.unlockedThemes);
    for (final skin in builtInThemes) {
      if (skin.unlockType == ThemeUnlockType.mission &&
          skin.unlockValue == missionId) {
        unlocked.add(skin.id);
      }
    }
    if (unlocked.length != _profile.unlockedThemes.length) {
      _profile = _profile.copyWith(unlockedThemes: unlocked);
    }
  }
}

class ProfileScope extends InheritedNotifier<ProfileManager> {
  const ProfileScope({
    super.key,
    required ProfileManager notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ProfileManager of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'ProfileScope not found in context');
    return scope!.notifier!;
  }
}
