import 'dart:math';

import 'direction.dart';
import 'food.dart';
import 'game_config.dart';
import 'grid.dart';

class Hazard {
  const Hazard({required this.position, required this.remainingTicks});

  final GridPosition position;
  final int remainingTicks;

  Hazard tick() => Hazard(
        position: position,
        remainingTicks: remainingTicks - 1,
      );
}

class _LaneShiftResult {
  const _LaneShiftResult({required this.snake, required this.hazards});

  final List<GridPosition> snake;
  final List<Hazard> hazards;
}

class CoopCoordinator {
  CoopCoordinator({
    required this.sessionId,
    required this.seed,
  });

  final String sessionId;
  final int seed;
  Direction? _remoteQueued;

  void submitRemoteDirection(Direction direction) {
    _remoteQueued = direction;
  }

  Direction? consumeRemoteDirection() {
    final direction = _remoteQueued;
    _remoteQueued = null;
    return direction;
  }
}

class SnakeGameState {
  SnakeGameState({
    required this.snake,
    required this.direction,
    required this.queuedDirection,
    required this.growth,
    required this.food,
    required this.score,
    required this.harmony,
    required this.lastFood,
    required this.phaseTurns,
    required this.isGameOver,
    required this.activeEffects,
    required this.hazards,
    required this.difficultyLevel,
    required this.hazardCooldown,
    required this.consumedThisTick,
    required this.hazardSpawnedThisTick,
  });

  final List<GridPosition> snake;
  final Direction direction;
  final Direction queuedDirection;
  final int growth;
  final Food food;
  final int score;
  final int harmony;
  final FoodType? lastFood;
  final int phaseTurns;
  final bool isGameOver;
  final Map<FoodEffect, int> activeEffects;
  final List<Hazard> hazards;
  final int difficultyLevel;
  final int hazardCooldown;
  final FoodType? consumedThisTick;
  final bool hazardSpawnedThisTick;

  GridPosition get head => snake.first;

  Duration get tickInterval {
    final base = GameConfig.baseTickMilliseconds -
        harmony * GameConfig.tickHarmonyReduction;
    final clamped = max(GameConfig.minTickMilliseconds, base);
    final slowTicks = activeEffects[FoodEffect.timeSlow] ?? 0;
    if (slowTicks > 0) {
      return Duration(
        milliseconds: (clamped * GameConfig.timeSlowMultiplier).round(),
      );
    }
    return Duration(milliseconds: clamped);
  }

  List<bool> get harmonySegments => List<bool>.generate(
        GameConfig.maxHarmony,
        (index) => index < harmony,
      );

  SnakeGameState copyWith({
    List<GridPosition>? snake,
    Direction? direction,
    Direction? queuedDirection,
    int? growth,
    Food? food,
    int? score,
    int? harmony,
    FoodType? lastFood,
    int? phaseTurns,
    bool? isGameOver,
    Map<FoodEffect, int>? activeEffects,
    List<Hazard>? hazards,
    int? difficultyLevel,
    int? hazardCooldown,
    FoodType? consumedThisTick,
    bool? hazardSpawnedThisTick,
  }) {
    return SnakeGameState(
      snake: snake ?? this.snake,
      direction: direction ?? this.direction,
      queuedDirection: queuedDirection ?? this.queuedDirection,
      growth: growth ?? this.growth,
      food: food ?? this.food,
      score: score ?? this.score,
      harmony: harmony ?? this.harmony,
      lastFood: lastFood ?? this.lastFood,
      phaseTurns: phaseTurns ?? this.phaseTurns,
      isGameOver: isGameOver ?? this.isGameOver,
      activeEffects: activeEffects ?? this.activeEffects,
      hazards: hazards ?? this.hazards,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      hazardCooldown: hazardCooldown ?? this.hazardCooldown,
      consumedThisTick: consumedThisTick ?? this.consumedThisTick,
      hazardSpawnedThisTick:
          hazardSpawnedThisTick ?? this.hazardSpawnedThisTick,
    );
  }
}

class SnakeGameEngine {
  SnakeGameEngine({
    required this.gridWidth,
    required this.gridHeight,
    required SnakeGameState initial,
    Random? random,
    this.seed,
    CoopCoordinator? coop,
  }) : _coop = coop {
    final rng = random ?? (seed != null ? Random(seed) : Random());
    _random = rng;
    state = initial;
  }

  final int gridWidth;
  final int gridHeight;
  final int? seed;
  final CoopCoordinator? _coop;
  late Random _random;

  bool get isCooperative => _coop != null;
  CoopCoordinator? get coordinator => _coop;

  factory SnakeGameEngine.standard({
    required int gridWidth,
    required int gridHeight,
    int? seed,
    Random? random,
  }) {
    final rng = random ?? (seed != null ? Random(seed) : Random());
    return SnakeGameEngine(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      initial: _createInitialState(gridWidth, gridHeight, rng),
      random: rng,
      seed: seed,
    );
  }

  factory SnakeGameEngine.cooperative({
    required int gridWidth,
    required int gridHeight,
    required CoopCoordinator coordinator,
    Random? random,
  }) {
    final rng = random ?? Random(coordinator.seed);
    return SnakeGameEngine(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      initial: _createInitialState(gridWidth, gridHeight, rng),
      random: rng,
      seed: coordinator.seed,
      coop: coordinator,
    );
  }

  late SnakeGameState _state;

  SnakeGameState get state => _state;
  set state(SnakeGameState next) => _state = next;

  void reset() {
    _random = seed != null ? Random(seed) : Random();
    state = _createInitialState(gridWidth, gridHeight, _random);
  }

  void queueDirection(Direction direction) {
    final current = state;
    if (current.isGameOver || direction.isOpposite(current.queuedDirection)) {
      return;
    }
    state = current.copyWith(queuedDirection: direction);
  }

  void submitRemoteDirection(Direction direction) {
    _coop?.submitRemoteDirection(direction);
  }

  void advance() {
    final current = state;
    if (current.isGameOver) {
      return;
    }

    final effects =
        Map<FoodEffect, int>.from(current.activeEffects);
    var hazards = current.hazards
        .map((hazard) =>
            Hazard(position: hazard.position, remainingTicks: hazard.remainingTicks))
        .toList();

    var food = current.food;
    final magnetActive = (effects[FoodEffect.magnet] ?? 0) > 0;
    if (magnetActive) {
      food = _pullFoodTowardsSnake(
        current.snake,
        food,
        hazards,
        gridWidth,
        gridHeight,
      );
    }

    final remoteDirection = _coop?.consumeRemoteDirection();
    final proposedDirection = remoteDirection != null &&
            !remoteDirection.isOpposite(current.direction)
        ? remoteDirection
        : current.queuedDirection;
    final direction = proposedDirection;
    final newHead = current.head.offset(direction);

    if (_isOutOfBounds(newHead, gridWidth, gridHeight)) {
      state = current.copyWith(isGameOver: true);
      return;
    }

    if (hazards.any((hazard) => hazard.position == newHead)) {
      state = current.copyWith(isGameOver: true);
      return;
    }

    final tail = current.snake.last;
    final consumedFood = food.position == newHead;
    final willGrow = consumedFood || current.growth > 0;
    final intersectsBody = current.snake.skip(1).contains(newHead);
    final phaseActive = current.phaseTurns > 0;
    if (intersectsBody && !phaseActive) {
      final tailEscaping = newHead == tail && !willGrow;
      if (!tailEscaping) {
        state = current.copyWith(isGameOver: true);
        return;
      }
    }

    var snake = <GridPosition>[newHead, ...current.snake];
    var growth = current.growth;
    var phaseTurns = current.phaseTurns;
    var score = current.score;
    var harmony = current.harmony;
    var lastFood = current.lastFood;
    var difficultyLevel = current.difficultyLevel;
    var hazardCooldown = max(0, current.hazardCooldown - 1);
    FoodType? consumedType;
    var hazardSpawned = false;

    if (consumedFood) {
      final metadata = current.food.type;
      consumedType = metadata;
      score += metadata.baseScore + harmony * 2;

      if (food.type == FoodType.prism) {
        harmony = GameConfig.maxHarmony;
      } else if (lastFood == null) {
        harmony = min(GameConfig.maxHarmony, harmony + 1);
      } else if (lastFood == food.type) {
        harmony =
            max(GameConfig.minHarmony, harmony - metadata.repeatPenalty);
      } else {
        harmony = min(GameConfig.maxHarmony, harmony + metadata.mixBoost);
      }

      if (metadata.phaseBonus > 0) {
        phaseTurns = min(
          GameConfig.maxPhaseTurns,
          phaseTurns + metadata.phaseBonus,
        );
      }

      growth += metadata.bonusGrowth;
      lastFood = metadata;

      if (metadata.effect == FoodEffect.laneShift) {
        final shiftResult = _applyLaneShift(
          snake,
          hazards,
          metadata.effectDuration,
          gridWidth,
          gridHeight,
        );
        snake = shiftResult.snake;
        hazards = shiftResult.hazards;
        if (_hasSelfCollision(snake) ||
            hazards.any((hazard) => hazard.position == snake.first)) {
          state = current.copyWith(isGameOver: true);
          return;
        }
      } else if (metadata.effect != FoodEffect.none) {
        effects[metadata.effect] = metadata.effectDuration;
      }

      food = _spawnFood(
        _random,
        snake,
        gridWidth,
        gridHeight,
        hazards,
      );
    } else {
      if (growth > 0) {
        growth -= 1;
      } else {
        snake.removeLast();
      }

      if (phaseTurns > 0) {
        phaseTurns -= 1;
      }
    }

    if (_hasSelfCollision(snake) && !(phaseActive && !consumedFood)) {
      state = current.copyWith(isGameOver: true);
      return;
    }

    hazards = hazards
        .map((hazard) => hazard.tick())
        .where((hazard) => hazard.remainingTicks > 0)
        .toList();

    if (harmony >= GameConfig.harmonyDifficultyThreshold &&
        hazardCooldown == 0 &&
        hazards.length < GameConfig.maxHazards) {
      difficultyLevel = min(
        GameConfig.maxDifficultyLevel,
        difficultyLevel + 1,
      );
      hazardCooldown = max(
        2,
        GameConfig.hazardSpawnInterval - difficultyLevel,
      );
      final hazard = _spawnHazard(
        _random,
        snake,
        food.position,
        hazards,
        gridWidth,
        gridHeight,
      );
      if (hazard != null) {
        hazards = [...hazards, hazard];
        hazardSpawned = true;
      }
    }

    final nextEffects = <FoodEffect, int>{};
    effects.forEach((effect, duration) {
      final next = duration - 1;
      if (next > 0) {
        nextEffects[effect] = next;
      }
    });

    state = SnakeGameState(
      snake: snake,
      direction: direction,
      queuedDirection: direction,
      growth: growth,
      food: food,
      score: score,
      harmony: harmony,
      lastFood: lastFood,
      phaseTurns: phaseTurns,
      isGameOver: false,
      activeEffects: nextEffects,
      hazards: hazards,
      difficultyLevel: difficultyLevel,
      hazardCooldown: hazardCooldown,
      consumedThisTick: consumedType,
      hazardSpawnedThisTick: hazardSpawned,
    );
  }
}

SnakeGameState _createInitialState(
  int gridWidth,
  int gridHeight,
  Random random,
) {
  final snake = _initialSnake(gridWidth, gridHeight);
  final hazards = <Hazard>[];
  final food = _spawnFood(random, snake, gridWidth, gridHeight, hazards);
  return SnakeGameState(
    snake: snake,
    direction: Direction.right,
    queuedDirection: Direction.right,
    growth: 0,
    food: food,
    score: 0,
    harmony: 3,
    lastFood: null,
    phaseTurns: 0,
    isGameOver: false,
    activeEffects: const {},
    hazards: hazards,
    difficultyLevel: 0,
    hazardCooldown: GameConfig.initialHazardCooldown,
    consumedThisTick: null,
    hazardSpawnedThisTick: false,
  );
}

List<GridPosition> _initialSnake(int gridWidth, int gridHeight) {
  final centerX = gridWidth ~/ 2;
  final centerY = gridHeight ~/ 2;
  return <GridPosition>[
    GridPosition(centerX + 1, centerY),
    GridPosition(centerX, centerY),
    GridPosition(centerX - 1, centerY),
  ];
}

Food _spawnFood(
  Random random,
  List<GridPosition> snake,
  int gridWidth,
  int gridHeight,
  List<Hazard> hazards,
) {
  final occupied = {
    for (final segment in snake) segment,
    for (final hazard in hazards) hazard.position,
  };
  final freeCells = <GridPosition>[];

  for (var y = 0; y < gridHeight; y += 1) {
    for (var x = 0; x < gridWidth; x += 1) {
      final position = GridPosition(x, y);
      if (!occupied.contains(position)) {
        freeCells.add(position);
      }
    }
  }

  if (freeCells.isEmpty) {
    return Food(position: snake.first, type: FoodType.prism);
  }

  final position = freeCells[random.nextInt(freeCells.length)];
  return Food(position: position, type: _pickFoodType(random));
}

FoodType _pickFoodType(Random random) {
  const weighted = <MapEntry<FoodType, int>>[
    MapEntry(FoodType.ember, 3),
    MapEntry(FoodType.tidal, 3),
    MapEntry(FoodType.gale, 4),
    MapEntry(FoodType.prism, 1),
    MapEntry(FoodType.chrono, 2),
    MapEntry(FoodType.magnetar, 2),
    MapEntry(FoodType.rift, 1),
  ];

  final totalWeight =
      weighted.fold<int>(0, (sum, entry) => sum + entry.value);
  final target = random.nextInt(totalWeight);
  var cumulative = 0;
  for (final entry in weighted) {
    cumulative += entry.value;
    if (target < cumulative) {
      return entry.key;
    }
  }

  return FoodType.gale;
}

bool _isOutOfBounds(GridPosition position, int gridWidth, int gridHeight) {
  return position.x < 0 ||
      position.y < 0 ||
      position.x >= gridWidth ||
      position.y >= gridHeight;
}

Food _pullFoodTowardsSnake(
  List<GridPosition> snake,
  Food food,
  List<Hazard> hazards,
  int gridWidth,
  int gridHeight,
) {
  final head = snake.first;
  final dx = head.x - food.position.x;
  final dy = head.y - food.position.y;
  final distance = dx.abs() + dy.abs();
  if (distance == 0 || distance > GameConfig.magnetRadius) {
    return food;
  }

  var stepX = 0;
  var stepY = 0;
  if (dx.abs() > dy.abs()) {
    stepX = dx.sign;
  } else if (dy != 0) {
    stepY = dy.sign;
  } else if (dx != 0) {
    stepX = dx.sign;
  }

  final nextPosition = GridPosition(
    (food.position.x + stepX).clamp(0, gridWidth - 1).toInt(),
    (food.position.y + stepY).clamp(0, gridHeight - 1).toInt(),
  );

  final occupiedPositions = {
    for (final segment in snake) segment,
    for (final hazard in hazards) hazard.position,
  };

  if (occupiedPositions.contains(nextPosition)) {
    return food;
  }

  return Food(position: nextPosition, type: food.type);
}

_LaneShiftResult _applyLaneShift(
  List<GridPosition> snake,
  List<Hazard> hazards,
  int rows,
  int gridWidth,
  int gridHeight,
) {
  if (rows == 0) {
    return _LaneShiftResult(snake: snake, hazards: hazards);
  }
  final shift = rows % gridHeight;
  final shiftedSnake = snake
      .map((segment) => _shiftPosition(segment, shift, gridHeight))
      .toList();
  final shiftedHazards = hazards
      .map(
        (hazard) => Hazard(
          position: _shiftPosition(hazard.position, shift, gridHeight),
          remainingTicks: hazard.remainingTicks,
        ),
      )
      .toList();
  return _LaneShiftResult(
    snake: shiftedSnake,
    hazards: shiftedHazards,
  );
}

GridPosition _shiftPosition(
  GridPosition position,
  int rows,
  int gridHeight,
) {
  final newY = (position.y + rows) % gridHeight;
  return GridPosition(position.x, newY);
}

bool _hasSelfCollision(List<GridPosition> snake) {
  final seen = <GridPosition>{};
  for (final segment in snake) {
    if (!seen.add(segment)) {
      return true;
    }
  }
  return false;
}

Hazard? _spawnHazard(
  Random random,
  List<GridPosition> snake,
  GridPosition foodPosition,
  List<Hazard> hazards,
  int gridWidth,
  int gridHeight,
) {
  final occupied = {
    for (final segment in snake) segment,
    foodPosition,
    for (final hazard in hazards) hazard.position,
  };
  final candidates = <GridPosition>[];

  for (var y = 0; y < gridHeight; y += 1) {
    for (var x = 0; x < gridWidth; x += 1) {
      final position = GridPosition(x, y);
      if (!occupied.contains(position)) {
        candidates.add(position);
      }
    }
  }

  if (candidates.isEmpty) {
    return null;
  }

  final position = candidates[random.nextInt(candidates.length)];
  return Hazard(
    position: position,
    remainingTicks: GameConfig.hazardLifetimeTicks,
  );
}
