import 'dart:convert';

import '../engine/snake_game_engine.dart';

class ReplayFrame {
  ReplayFrame({
    required this.tick,
    required this.snakePositions,
    required this.foodPosition,
    required this.score,
  });

  final int tick;
  final List<Map<String, int>> snakePositions;
  final Map<String, int> foodPosition;
  final int score;

  Map<String, dynamic> toJson() => {
        'tick': tick,
        'snake': snakePositions,
        'food': foodPosition,
        'score': score,
      };
}

class ReplayRecorder {
  ReplayRecorder();

  final List<ReplayFrame> _frames = [];
  bool _recording = false;
  int _tick = 0;

  void start() {
    _frames.clear();
    _recording = true;
    _tick = 0;
  }

  void stop() {
    _recording = false;
  }

  void capture(SnakeGameState state) {
    if (!_recording) return;
    _frames.add(
      ReplayFrame(
        tick: _tick,
        snakePositions: state.snake
            .map((segment) => {'x': segment.x, 'y': segment.y})
            .toList(),
        foodPosition: {
          'x': state.food.position.x,
          'y': state.food.position.y,
        },
        score: state.score,
      ),
    );
    _tick += 1;
  }

  bool get isRecording => _recording;
  bool get hasFrames => _frames.isNotEmpty;

  String exportJson() {
    final payload = {
      'version': 1,
      'frames': _frames.map((frame) => frame.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
