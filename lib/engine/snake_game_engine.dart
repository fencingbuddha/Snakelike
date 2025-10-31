import 'dart:math';

import 'direction.dart';
import 'food.dart';
import 'game_config.dart';
import 'grid.dart';

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

  GridPosition get head => snake.first;

  Duration get tickInterval {
    final base =
        GameConfig.baseTickMilliseconds - harmony * GameConfig.tickHarmonyReduction;
    final clamped = max(GameConfig.minTickMilliseconds, base);
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
    );
  }
}

class SnakeGameEngine {
  SnakeGameEngine({
    required this.gridWidth,
    required this.gridHeight,
    required SnakeGameState initial,
    Random? random,
  }) : _random = random ?? Random() {
    this.state = initial;
  }

  final int gridWidth;
  final int gridHeight;

  factory SnakeGameEngine.standard({
    required int gridWidth,
    required int gridHeight,
    Random? random,
  }) {
    final rng = random ?? Random();
    return SnakeGameEngine(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      initial: _createInitialState(gridWidth, gridHeight, rng),
      random: rng,
    );
  }

  late SnakeGameState _state;
  final Random _random;

  SnakeGameState get state => _state;
  set state(SnakeGameState next) => _state = next;

  void reset() {
    state = _createInitialState(gridWidth, gridHeight, _random);
  }

  void queueDirection(Direction direction) {
    final current = state;
    if (current.isGameOver || direction.isOpposite(current.queuedDirection)) {
      return;
    }
    state = current.copyWith(queuedDirection: direction);
  }

  void advance() {
    final current = state;
    if (current.isGameOver) {
      return;
    }

    final direction = current.queuedDirection;
    final newHead = current.head.offset(direction);

    if (_isOutOfBounds(newHead, gridWidth, gridHeight)) {
      state = current.copyWith(isGameOver: true);
      return;
    }

    final tail = current.snake.last;
    final consumedFood = current.food.position == newHead;
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

    final body = <GridPosition>[newHead, ...current.snake];
    var growth = current.growth;
    var phaseTurns = current.phaseTurns;
    var score = current.score;
    var harmony = current.harmony;
    var lastFood = current.lastFood;
    var snake = body;
    var food = current.food;

    if (consumedFood) {
      final metadata = food.type;
      score += metadata.baseScore + harmony * 2;

      if (food.type == FoodType.prism) {
        harmony = GameConfig.maxHarmony;
      } else if (lastFood == null) {
        harmony = min(GameConfig.maxHarmony, harmony + 1);
      } else if (lastFood == food.type) {
        harmony = max(GameConfig.minHarmony, harmony - metadata.repeatPenalty);
      } else {
        harmony = min(GameConfig.maxHarmony, harmony + metadata.mixBoost);
      }

      if (metadata.phaseBonus > 0) {
        phaseTurns = min(GameConfig.maxPhaseTurns, phaseTurns + metadata.phaseBonus);
      }

      growth += metadata.bonusGrowth;
      lastFood = food.type;
      food = _spawnFood(_random, snake, gridWidth, gridHeight);
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
    );
  }
}

SnakeGameState _createInitialState(
  int gridWidth,
  int gridHeight,
  Random random,
) {
  final snake = _initialSnake(gridWidth, gridHeight);
  final food = _spawnFood(random, snake, gridWidth, gridHeight);
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
  List<GridPosition> excluding,
  int gridWidth,
  int gridHeight,
) {
  final occupied = excluding.toSet();
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
    return Food(position: excluding.first, type: FoodType.prism);
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
  ];

  final totalWeight = weighted.fold<int>(0, (sum, entry) => sum + entry.value);
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
