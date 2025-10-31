import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  SnakeGameEngine? _engine;
  late final Ticker _ticker;
  Duration? _lastTickTimestamp;
  Duration _tickAccumulator = Duration.zero;
  Duration _sinceGlowFrame = Duration.zero;
  double _glowPhase = 0;
  Offset _panDelta = Offset.zero;
  bool _panDirectionCommitted = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureEngine(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final maxHeight = constraints.maxHeight;
    if (maxWidth <= 0 || maxHeight <= 0) {
      return;
    }

    final gridWidth = GameConfig.gridWidth;
    final cellSizeByWidth = maxWidth / gridWidth;
    final possibleRows = maxHeight > 0
        ? (maxHeight / cellSizeByWidth).floor()
        : GameConfig.minGridHeight;
    final targetHeight = max(GameConfig.minGridHeight, possibleRows);

    if (_engine == null || _engine!.gridHeight != targetHeight) {
      _engine = SnakeGameEngine.standard(
        gridWidth: gridWidth,
        gridHeight: targetHeight,
      );
      _tickAccumulator = Duration.zero;
      _lastTickTimestamp = null;
    }
  }

  void _handleTick(Duration elapsed) {
    final engine = _engine;
    if (engine == null) {
      _lastTickTimestamp = elapsed;
      return;
    }

    final previous = _lastTickTimestamp;
    _lastTickTimestamp = elapsed;
    if (previous == null) {
      return;
    }

    final delta = elapsed - previous;
    _tickAccumulator += delta;
    _sinceGlowFrame += delta;
    _glowPhase =
        (_glowPhase + delta.inMicroseconds / Duration.microsecondsPerSecond) %
            (2 * pi);

    var didAdvance = false;
    while (true) {
      final interval = engine.state.tickInterval;
      if (_tickAccumulator < interval) {
        break;
      }
      _tickAccumulator -= interval;
      engine.advance();
      didAdvance = true;
      if (engine.state.isGameOver) {
        _tickAccumulator = Duration.zero;
        break;
      }
    }

    var shouldRepaint = didAdvance;
    const glowFrameInterval = Duration(milliseconds: 32);
    if (!shouldRepaint && _sinceGlowFrame >= glowFrameInterval) {
      shouldRepaint = true;
      _sinceGlowFrame = Duration.zero;
    } else if (didAdvance) {
      _sinceGlowFrame = Duration.zero;
    }

    if (shouldRepaint && mounted) {
      setState(() {});
    }
  }

  void _restart() {
    final engine = _engine;
    if (engine == null) {
      return;
    }
    engine.reset();
    _tickAccumulator = Duration.zero;
    _lastTickTimestamp = null;
    _sinceGlowFrame = Duration.zero;
    setState(() {});
  }

  void _handlePanStart(DragStartDetails details) {
    _panDelta = Offset.zero;
    _panDirectionCommitted = false;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final engine = _engine;
    if (engine == null) {
      return;
    }
    _panDelta += details.delta;
    if (_panDirectionCommitted) {
      return;
    }
    const threshold = 12.0;
    final dx = _panDelta.dx;
    final dy = _panDelta.dy;
    if (dx.abs() < threshold && dy.abs() < threshold) {
      return;
    }
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        engine.queueDirection(Direction.right);
      } else {
        engine.queueDirection(Direction.left);
      }
    } else {
      if (dy > 0) {
        engine.queueDirection(Direction.down);
      } else {
        engine.queueDirection(Direction.up);
      }
    }
    _panDirectionCommitted = true;
  }

  void _handlePanEnd(DragEndDetails details) {
    _panDelta = Offset.zero;
    _panDirectionCommitted = false;
  }

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            _ensureEngine(constraints);
            final engine = _engine;
            if (engine == null) {
              return const SizedBox.shrink();
            }
            final state = engine.state;
            return Stack(
              children: [
                Positioned.fill(
                  child: _GameBoard(
                    state: state,
                    gridWidth: engine.gridWidth,
                    gridHeight: engine.gridHeight,
                    glowPhase: _glowPhase,
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 32),
                    color: Colors.white.withOpacity(0.9),
                    onPressed: () {
                      _ticker.stop();
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
            );
          },
        ),
      ),
    );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({
    required this.state,
    required this.gridWidth,
    required this.gridHeight,
    required this.glowPhase,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final SnakeGameState state;
  final int gridWidth;
  final int gridHeight;
  final double glowPhase;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xff05070f),
        ),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _BoardPainter(
              state,
              gridWidth: gridWidth,
              gridHeight: gridHeight,
              glowPhase: glowPhase,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(
    this.state, {
    required this.gridWidth,
    required this.gridHeight,
    required this.glowPhase,
  });

  final SnakeGameState state;
  final int gridWidth;
  final int gridHeight;
  final double glowPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final widthPerCell = size.width / gridWidth;
    final heightPerCell = size.height / gridHeight;
    final cellSize = min(widthPerCell, heightPerCell);
    final boardWidth = cellSize * gridWidth;
    final boardHeight = cellSize * gridHeight;
    final offsetX = (size.width - boardWidth) / 2;
    final offsetY = 0.0;
    final boardRect = Rect.fromLTWH(offsetX, offsetY, boardWidth, boardHeight);
    final borderPaint = Paint()
      ..color = const Color(0xff0b1329)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final backgroundPaint = Paint()..color = const Color(0xff070b18);
    canvas.drawRect(boardRect, backgroundPaint);

    final glowPulse = (sin(glowPhase) + 1) / 2;
    final foodPulse = (sin(glowPhase * 1.6) + 1) / 2;
    final gridAlpha = 0.25 + glowPulse * 0.1;

    for (var y = 0; y < gridHeight; y += 1) {
      for (var x = 0; x < gridWidth; x += 1) {
        final rect = Rect.fromLTWH(
          offsetX + (x * cellSize),
          offsetY + (y * cellSize),
          cellSize,
          cellSize,
        );
        canvas.drawRect(
          rect,
          borderPaint
            ..color = const Color(0xff0b1329).withOpacity(gridAlpha)
            ..strokeWidth = 0.6,
        );
      }
    }

    final foodRect = Rect.fromLTWH(
      offsetX + state.food.position.x * cellSize,
      offsetY + state.food.position.y * cellSize,
      cellSize,
      cellSize,
    );
    final foodColor = Color(state.food.type.colorHex);
    final foodRadius = cellSize * 0.3;
    final foodGlowPaint = Paint()
      ..color = foodColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * (0.28 + foodPulse * 0.12)
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, cellSize * (0.7 + foodPulse * 0.4));
    final foodGlowRect = RRect.fromRectXY(
        foodRect.inflate(cellSize * (0.45 + foodPulse * 0.2)),
        foodRadius,
        foodRadius);
    canvas.drawRRect(foodGlowRect, foodGlowPaint);

    final foodFill = Paint()
      ..shader = RadialGradient(
        colors: [
          foodColor.withOpacity(0.95),
          foodColor.withOpacity(0.6),
        ],
      ).createShader(foodRect);
    final foodBorder = Paint()
      ..color = Colors.white.withOpacity(0.2 + foodPulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.08;
    final foodRRect = RRect.fromRectXY(
        foodRect.deflate(cellSize * 0.1), foodRadius, foodRadius);
    canvas.drawRRect(foodRRect, foodFill);
    canvas.drawRRect(foodRRect.deflate(cellSize * 0.04), foodBorder);

    for (var i = state.snake.length - 1; i >= 0; i -= 1) {
      final segment = state.snake[i];
      final rect = Rect.fromLTWH(
        offsetX + segment.x * cellSize,
        offsetY + segment.y * cellSize,
        cellSize,
        cellSize,
      );
      final isHead = i == 0;
      final segmentColor = isHead
          ? const Color(0xff61dbff)
          : const Color(0xff32e0c4).withOpacity(0.9);
      final glowSigma = cellSize * (0.7 + glowPulse * 0.5);
      final glowExpansion = cellSize * (0.45 + glowPulse * 0.3);
      final glowPaint = Paint()
        ..color = segmentColor.withOpacity(isHead ? 0.7 : 0.5 + glowPulse * 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma);
      final glowRRect = RRect.fromRectXY(
        rect.inflate(glowExpansion),
        cellSize * 0.7,
        cellSize * 0.7,
      );
      canvas.drawRRect(glowRRect, glowPaint);

      final fillRRect = RRect.fromRectXY(
        rect.deflate(cellSize * 0.12),
        cellSize * 0.4,
        cellSize * 0.4,
      );
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            segmentColor.withOpacity(0.95),
            segmentColor.withOpacity(0.65),
          ],
        ).createShader(rect);
      canvas.drawRRect(fillRRect, fillPaint);

      final border = Paint()
        ..color = (isHead ? const Color(0xffc8f3ff) : const Color(0xff22b498))
            .withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.1;
      canvas.drawRRect(fillRRect.deflate(cellSize * 0.05), border);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.gridWidth != gridWidth ||
      oldDelegate.gridHeight != gridHeight ||
      oldDelegate.glowPhase != glowPhase;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
