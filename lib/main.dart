import 'dart:async';

import 'package:flutter/material.dart';

import 'engine/direction.dart';
import 'engine/food.dart';
import 'engine/game_config.dart';
import 'engine/grid.dart';
import 'engine/snake_game_engine.dart';

void main() {
  runApp(const ChromaticCurrentApp());
}

class ChromaticCurrentApp extends StatelessWidget {
  const ChromaticCurrentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chromatic Current',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'SF Pro Display',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff61dbff),
          secondary: Color(0xff32e0c4),
        ),
        scaffoldBackgroundColor: const Color(0xff060913),
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isPlaying
          ? GameScreen(
              key: const ValueKey('game'),
              onExit: () {
                setState(() {
                  _isPlaying = false;
                });
              },
            )
          : MainMenuScreen(
              key: const ValueKey('menu'),
              onStart: () {
                setState(() {
                  _isPlaying = true;
                });
              },
            ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  LinearGradient get _gradient => const LinearGradient(
        colors: [Color(0xff060913), Color(0xff0d1324)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Chromatic Current',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ride the elemental wave and keep your harmony flowing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff8f9bb5),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff61dbff),
                  foregroundColor: const Color(0xff05070f),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: onStart,
                child: const Text('Start Run'),
              ),
              const SizedBox(height: 48),
              const _LegendPanel(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.onExit});

  final VoidCallback onExit;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SnakeGameEngine _engine;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _engine = SnakeGameEngine.standard();
    _scheduleTick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleTick() {
    _timer?.cancel();
    if (_engine.state.isGameOver) {
      return;
    }
    _timer = Timer(_engine.state.tickInterval, () {
      _engine.advance();
      if (mounted) {
        setState(() {});
        _scheduleTick();
      }
    });
  }

  void _restart() {
    _engine.reset();
    setState(() {});
    _scheduleTick();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    final dy = details.delta.dy;
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        _engine.queueDirection(Direction.right);
      } else {
        _engine.queueDirection(Direction.left);
      }
    } else {
      if (dy > 0) {
        _engine.queueDirection(Direction.down);
      } else {
        _engine.queueDirection(Direction.up);
      }
    }
    setState(() {});
  }

  LinearGradient get _gradient => const LinearGradient(
        colors: [Color(0xff060913), Color(0xff0d1324)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    final state = _engine.state;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: _gradient),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(state: state),
                  const SizedBox(height: 16),
                  _HarmonyMeter(state: state),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _GameBoard(
                      state: state,
                      onPanUpdate: _handlePanUpdate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _LegendPanel(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 32),
                color: Colors.white.withOpacity(0.9),
                onPressed: () {
                  _timer?.cancel();
                  widget.onExit();
                },
              ),
            ),
            if (state.isGameOver)
              Positioned.fill(
                child: _GameOverOverlay(
                  onRestart: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final SnakeGameState state;

  @override
  Widget build(BuildContext context) {
    final clampedPhase = state.phaseTurns.clamp(0, GameConfig.maxPhaseTurns).toInt();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Chromatic Current',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Keep your elemental harmony high by weaving between different blooms.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xff8f9bb5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff0d1324),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xff1f2a4c)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Score',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff6c7aa1),
                ),
              ),
              Text(
                '${state.score}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Phase $clampedPhase',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff7dd3fc),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HarmonyMeter extends StatelessWidget {
  const _HarmonyMeter({required this.state});

  final SnakeGameState state;

  @override
  Widget build(BuildContext context) {
    final segments = state.harmonySegments;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff0d1324),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff1b243d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harmony',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff9bb5ff),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (index, filled) in segments.indexed)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index == segments.length - 1 ? 0 : 6),
                    height: 12,
                    decoration: BoxDecoration(
                      color: filled ? const Color(0xff61dbff) : const Color(0xff1a2542),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xff1b243d)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.lastFood != null
                ? 'Last: ${state.lastFood!.label}'
                : 'Grab different blooms to build harmony.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: state.lastFood != null
                  ? Color(state.lastFood!.colorHex)
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({required this.state, required this.onPanUpdate});

  final SnakeGameState state;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        return Center(
          child: GestureDetector(
            onPanUpdate: onPanUpdate,
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff05070f),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xff10182d)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(
                      painter: _BoardPainter(state),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.state);

  final SnakeGameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GameConfig.gridSize;
    final borderPaint = Paint()
      ..color = const Color(0xff0b1329)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final backgroundPaint = Paint()..color = const Color(0xff070b18);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    for (var y = 0; y < GameConfig.gridSize; y += 1) {
      for (var x = 0; x < GameConfig.gridSize; x += 1) {
        final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, borderPaint);
      }
    }

    final foodRect = Rect.fromLTWH(
      state.food.position.x * cellSize,
      state.food.position.y * cellSize,
      cellSize,
      cellSize,
    );
    final foodPaint = Paint()
      ..color = Color(state.food.type.colorHex)
      ..style = PaintingStyle.fill;
    final foodBorder = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(foodRect, foodPaint);
    canvas.drawRect(foodRect.deflate(0.5), foodBorder);

    for (var i = state.snake.length - 1; i >= 0; i -= 1) {
      final segment = state.snake[i];
      final rect = Rect.fromLTWH(segment.x * cellSize, segment.y * cellSize, cellSize, cellSize);
      final paint = Paint()
        ..color = i == 0 ? const Color(0xff61dbff) : const Color(0xff32e0c4);
      final border = Paint()
        ..color = i == 0 ? const Color(0xff9bf6ff) : const Color(0xff22b498)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect.deflate(0.5), border);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.state != state;
}

class _LegendPanel extends StatelessWidget {
  const _LegendPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff0d1324),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff1f2a4c)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elemental Effects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...FoodType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color(type.colorHex),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff8f9bb5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Matching colors repeatedly drains harmony. Fill the meter to speed up and gain bigger score bonuses!',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff6c7aa1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Harmony Shattered',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your chromatic current collapsed.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff9bb5ff),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff61dbff),
                foregroundColor: const Color(0xff05070f),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: onRestart,
              child: const Text('Restart Run'),
            ),
          ],
        ),
      ),
    );
  }
}
