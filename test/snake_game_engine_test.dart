import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:updated_snake_game/engine/direction.dart';
import 'package:updated_snake_game/engine/food.dart';
import 'package:updated_snake_game/engine/game_config.dart';
import 'package:updated_snake_game/engine/grid.dart';
import 'package:updated_snake_game/engine/snake_game_engine.dart';

class DeterministicRandom implements Random {
  DeterministicRandom(this.values);

  final List<int> values;
  var _index = 0;

  int _nextValue() {
    if (values.isEmpty) {
      return 0;
    }
    final value = values[_index % values.length];
    _index += 1;
    return value;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'Must be positive');
    }
    final value = _nextValue();
    return value % max;
  }

  @override
  double nextDouble() => (_nextValue() & 0xffff) / 0xffff;

  @override
  bool nextBool() => (_nextValue() & 1) == 1;
}

void main() {
  group('SnakeGameEngine', () {
    test('starts with expected defaults', () {
      final engine = SnakeGameEngine.standard(
        gridWidth: GameConfig.gridWidth,
        gridHeight: GameConfig.minGridHeight,
        random: DeterministicRandom([0, 1, 2]),
      );
      final state = engine.state;

      expect(state.snake.length, 3);
      expect(state.direction, Direction.right);
      expect(state.score, 0);
      expect(state.harmony, 3);
      expect(state.isGameOver, isFalse);
      expect(state.food.position.x, inInclusiveRange(0, GameConfig.gridWidth - 1));
      expect(
        state.food.position.y,
        inInclusiveRange(0, GameConfig.minGridHeight - 1),
      );
    });

    test('moving without food consumes tail', () {
      final engine = SnakeGameEngine.standard(
        gridWidth: GameConfig.gridWidth,
        gridHeight: GameConfig.minGridHeight,
        random: DeterministicRandom([0, 1, 2]),
      );
      final initialSnake = List<GridPosition>.from(engine.state.snake);

      engine.advance();
      final updated = engine.state.snake;

      expect(updated.length, initialSnake.length);
      expect(updated.contains(initialSnake.last), isFalse);
    });

    test('food consumption boosts score and growth', () {
      final engine = SnakeGameEngine.standard(
        gridWidth: GameConfig.gridWidth,
        gridHeight: GameConfig.minGridHeight,
        random: DeterministicRandom([0]),
      );
      final state = engine.state;
      final head = state.head;
      final forward = head.offset(state.direction);

      engine.queueDirection(state.direction);
      engine.state = state.copyWith(
        food: Food(position: forward, type: FoodType.ember),
      );
      engine.advance();

      expect(engine.state.score, greaterThan(0));
      expect(engine.state.lastFood, FoodType.ember);
      expect(engine.state.harmony, greaterThanOrEqualTo(state.harmony));
    });

    test('repeating food penalizes harmony', () {
      final engine = SnakeGameEngine.standard(
        gridWidth: GameConfig.gridWidth,
        gridHeight: GameConfig.minGridHeight,
        random: DeterministicRandom([0]),
      );
      final state = engine.state;
      final head = state.head;
      final forward = head.offset(state.direction);

      engine.state = state.copyWith(
        food: Food(position: forward, type: FoodType.ember),
        lastFood: FoodType.ember,
      );
      engine.advance();

      expect(engine.state.harmony, lessThanOrEqualTo(state.harmony));
    });

    test('phase turns allow self intersection', () {
      final engine = SnakeGameEngine.standard(
        gridWidth: GameConfig.gridWidth,
        gridHeight: GameConfig.minGridHeight,
        random: DeterministicRandom([0]),
      );
      final head = engine.state.head;
      final right = head.offset(Direction.right);

      final loopSnake = [
        right,
        head,
        GridPosition(head.x - 1, head.y),
        GridPosition(head.x - 1, head.y + 1),
        GridPosition(head.x, head.y + 1),
      ];

      engine.state = engine.state.copyWith(
        snake: loopSnake,
        direction: Direction.up,
        queuedDirection: Direction.up,
        phaseTurns: 2,
        food: Food(position: GridPosition(head.x, head.y - 1), type: FoodType.tidal),
      );
      engine.advance();

      expect(engine.state.isGameOver, isFalse);
    });

    test('collision without phase ends game', () {
      final engine = SnakeGameEngine.standard(
        gridWidth: GameConfig.gridWidth,
        gridHeight: GameConfig.minGridHeight,
        random: DeterministicRandom([0]),
      );
      final head = engine.state.head;
      final right = head.offset(Direction.right);

      engine.state = engine.state.copyWith(
        snake: [
          right,
          head,
          GridPosition(head.x - 1, head.y),
          GridPosition(head.x - 1, head.y + 1),
          GridPosition(head.x, head.y + 1),
        ],
        direction: Direction.up,
        queuedDirection: Direction.left,
        phaseTurns: 0,
      );
      engine.advance();

      expect(engine.state.isGameOver, isTrue);
    });
  });
}
