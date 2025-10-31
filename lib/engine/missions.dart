import 'dart:math';

import 'food.dart';

enum MissionCadence { daily, weekly }

enum MissionKind {
  collectFoodType,
  reachPhase,
  scorePoints,
}

class Mission {
  const Mission({
    required this.id,
    required this.cadence,
    required this.kind,
    required this.description,
    required this.target,
    required this.progress,
    this.foodType,
  });

  final String id;
  final MissionCadence cadence;
  final MissionKind kind;
  final String description;
  final int target;
  final int progress;
  final FoodType? foodType;

  bool get isComplete => progress >= target;

  Mission copyWith({int? progress}) {
    return Mission(
      id: id,
      cadence: cadence,
      kind: kind,
      description: description,
      target: target,
      progress: progress ?? this.progress,
      foodType: foodType,
    );
  }

  Mission addProgress(int amount) {
    if (amount <= 0 || isComplete) {
      return this;
    }
    return copyWith(progress: min(target, progress + amount));
  }
}

class MissionSet {
  const MissionSet({required this.daily, required this.weekly});

  final List<Mission> daily;
  final List<Mission> weekly;
}

class MissionGenerator {
  const MissionGenerator._();

  static MissionSet generate(DateTime now) {
    final dailySeed = _seedFromDate(now, MissionCadence.daily);
    final weeklySeed = _seedFromDate(now, MissionCadence.weekly);
    return MissionSet(
      daily: _generateDailyMissions(dailySeed),
      weekly: _generateWeeklyMissions(weeklySeed),
    );
  }

  static List<Mission> _generateDailyMissions(int seed) {
    final random = Random(seed);
    final missions = <Mission>[];
    final foodTypes = FoodType.values
        .where((type) => type != FoodType.prism)
        .toList();
    final targetFood = foodTypes[random.nextInt(foodTypes.length)];
    missions.add(
      Mission(
        id: 'daily_collect_${targetFood.name}',
        cadence: MissionCadence.daily,
        kind: MissionKind.collectFoodType,
        description: 'Collect ${GameConfigDaily.collectTarget} ${targetFood.label}s',
        target: GameConfigDaily.collectTarget,
        progress: 0,
        foodType: targetFood,
      ),
    );
    missions.add(
      Mission(
        id: 'daily_phase_${GameConfigDaily.phaseTarget}',
        cadence: MissionCadence.daily,
        kind: MissionKind.reachPhase,
        description: 'Reach phase ${GameConfigDaily.phaseTarget}',
        target: GameConfigDaily.phaseTarget,
        progress: 0,
      ),
    );
    return missions;
  }

  static List<Mission> _generateWeeklyMissions(int seed) {
    final random = Random(seed);
    return [
      Mission(
        id: 'weekly_prism_${GameConfigWeekly.prismTarget}',
        cadence: MissionCadence.weekly,
        kind: MissionKind.collectFoodType,
        description:
            'Absorb ${GameConfigWeekly.prismTarget} Prism Cores this week',
        target: GameConfigWeekly.prismTarget,
        progress: 0,
        foodType: FoodType.prism,
      ),
      Mission(
        id: 'weekly_score_${GameConfigWeekly.scoreTarget}',
        cadence: MissionCadence.weekly,
        kind: MissionKind.scorePoints,
        description:
            'Bank ${GameConfigWeekly.scoreTarget} total points across runs',
        target: GameConfigWeekly.scoreTarget,
        progress: 0,
      ),
    ];
  }

  static int _seedFromDate(DateTime date, MissionCadence cadence) {
    switch (cadence) {
      case MissionCadence.daily:
        return date.year * 10000 + date.month * 100 + date.day;
      case MissionCadence.weekly:
        final firstDayOfYear = DateTime(date.year, 1, 1);
        final dayOfYear = date.difference(firstDayOfYear).inDays;
        final weekIndex = dayOfYear ~/ 7;
        return date.year * 100 + weekIndex;
    }
  }
}

class GameConfigDaily {
  static const int collectTarget = 8;
  static const int phaseTarget = 5;
}

class GameConfigWeekly {
  static const int prismTarget = 6;
  static const int scoreTarget = 2000;
}
