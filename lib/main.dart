import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum _HapticIntensity { light, heavy }

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  SnakeGameEngine? _engine;
  late final Ticker _ticker;
  Duration? _lastTickTimestamp;
  Duration _tickAccumulator = Duration.zero;
  Duration _sinceGlowFrame = Duration.zero;
  double _glowPhase = 0;
  Offset _panDelta = Offset.zero;
  bool _panDirectionCommitted = false;
  Offset _parallaxOffset = Offset.zero;
  double _foodPulseProgress = 0;
  late final AnimationController _shakeController;
  late final AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick)..start();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _flashController.value = 1;
          _flashController.stop();
        }
      });
    _flashController.value = 1;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
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
      _sinceGlowFrame = Duration.zero;
      _parallaxOffset = Offset.zero;
      _foodPulseProgress = 0;
      _shakeController.stop();
      _shakeController.value = 0;
      _flashController.stop();
      _flashController.value = 1;
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
    var consumedFood = false;
    var collisionTriggered = false;
    while (true) {
      final beforeState = engine.state;
      final beforeScore = beforeState.score;
      final beforeGameOver = beforeState.isGameOver;
      final interval = engine.state.tickInterval;
      if (_tickAccumulator < interval) {
        break;
      }
      _tickAccumulator -= interval;
      engine.advance();
      didAdvance = true;
      final afterState = engine.state;
      if (afterState.score > beforeScore) {
        consumedFood = true;
      }
      if (!beforeGameOver && afterState.isGameOver) {
        collisionTriggered = true;
      }
      if (afterState.isGameOver) {
        _tickAccumulator = Duration.zero;
        break;
      }
    }

    final direction = engine.state.direction;
    final directionOffset = engine.state.isGameOver
        ? Offset.zero
        : Offset(direction.dx.toDouble(), direction.dy.toDouble()) * 18;
    _parallaxOffset = Offset.lerp(_parallaxOffset, directionOffset, 0.12)!;

    if (consumedFood) {
      _foodPulseProgress = 1;
      _triggerHaptic(_HapticIntensity.light);
    } else if (_foodPulseProgress > 0) {
      final decay = delta.inMilliseconds / 480.0;
      _foodPulseProgress = max(0, _foodPulseProgress - decay);
    }

    if (collisionTriggered) {
      _triggerHaptic(_HapticIntensity.heavy);
      _shakeController.forward(from: 0);
      _flashController.forward(from: 0);
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
    _glowPhase = 0;
    _parallaxOffset = Offset.zero;
    _foodPulseProgress = 0;
    _shakeController.stop();
    _shakeController.value = 0;
    _flashController.stop();
    _flashController.value = 1;
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

  void _triggerHaptic(_HapticIntensity intensity) {
    try {
      switch (intensity) {
        case _HapticIntensity.light:
          HapticFeedback.selectionClick();
          break;
        case _HapticIntensity.heavy:
          HapticFeedback.heavyImpact();
          break;
      }
    } catch (_) {
      // Haptics are best-effort; ignore platform exceptions.
    }
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
            final shakeProgress = _shakeController.value.clamp(0.0, 1.0);
            final easedShake = Curves.easeOutQuad.transform(shakeProgress);
            final shakeDamp = (1 - easedShake) * (1 - easedShake);
            final shakeOffset = Offset(
              sin(shakeProgress * pi * 12) * 18 * shakeDamp,
              sin(shakeProgress * pi * 9 + pi / 2) * 12 * shakeDamp,
            );
            double flashOpacity = 0;
            if (_flashController.isAnimating || _flashController.value < 1) {
              final t = _flashController.value.clamp(0.0, 1.0);
              flashOpacity = 1 - Curves.easeOutQuad.transform(t);
            }
            final flashColor = state.lastFood != null
                ? Color(state.lastFood!.colorHex)
                : const Color(0xff8de7ff);
            return Stack(
              children: [
                Positioned.fill(
                  child: _ParallaxBackground(
                    offset: _parallaxOffset,
                    glowPhase: _glowPhase,
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: shakeOffset,
                    child: _GameBoard(
                      state: state,
                      gridWidth: engine.gridWidth,
                      gridHeight: engine.gridHeight,
                      glowPhase: _glowPhase,
                      foodPulseProgress: _foodPulseProgress,
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                    ),
                  ),
                ),
                if (flashOpacity > 0.01)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ShaderMask(
                        shaderCallback: (rect) => RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            flashColor.withOpacity(0.8 * flashOpacity),
                            Colors.transparent,
                          ],
                        ).createShader(rect),
                        blendMode: BlendMode.plus,
                        child: Container(
                          color: flashColor.withOpacity(0.16 * flashOpacity),
                        ),
                      ),
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
    required this.foodPulseProgress,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final SnakeGameState state;
  final int gridWidth;
  final int gridHeight;
  final double glowPhase;
  final double foodPulseProgress;
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
              foodPulseProgress: foodPulseProgress,
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
    required this.foodPulseProgress,
  });

  final SnakeGameState state;
  final int gridWidth;
  final int gridHeight;
  final double glowPhase;
  final double foodPulseProgress;

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
    final pulseBoost = foodPulseProgress.clamp(0, 1);
    final gridAlpha = 0.25 + glowPulse * 0.1 + pulseBoost * 0.08;

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
      ..color = foodColor.withOpacity(0.55 + pulseBoost * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * (0.28 + foodPulse * 0.12 + pulseBoost * 0.3)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        cellSize * (0.7 + foodPulse * 0.4 + pulseBoost * 0.6),
      );
    final foodGlowRect = RRect.fromRectXY(
        foodRect
            .inflate(cellSize * (0.45 + foodPulse * 0.2 + pulseBoost * 0.35)),
        foodRadius,
        foodRadius);
    canvas.drawRRect(foodGlowRect, foodGlowPaint);

    final foodFill = Paint()
      ..shader = RadialGradient(
        colors: [
          foodColor.withOpacity(0.95),
          foodColor.withOpacity(0.6 - pulseBoost * 0.2),
        ],
      ).createShader(foodRect);
    final foodBorder = Paint()
      ..color =
          Colors.white.withOpacity(0.2 + foodPulse * 0.2 + pulseBoost * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * (0.08 + pulseBoost * 0.04);
    final foodRRect = RRect.fromRectXY(
        foodRect.deflate(cellSize * (0.1 - pulseBoost * 0.04)),
        foodRadius,
        foodRadius);
    canvas.drawRRect(foodRRect, foodFill);
    canvas.drawRRect(
      foodRRect.deflate(cellSize * (0.04 + pulseBoost * 0.02)),
      foodBorder,
    );

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
      final glowSigma = cellSize * (0.7 + glowPulse * 0.5 + pulseBoost * 0.6);
      final glowExpansion =
          cellSize * (0.45 + glowPulse * 0.3 + pulseBoost * 0.25);
      final glowPaint = Paint()
        ..color = segmentColor.withOpacity(isHead
            ? 0.75 + pulseBoost * 0.2
            : 0.5 + glowPulse * 0.2 + pulseBoost * 0.2)
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
            .withOpacity(0.8 + pulseBoost * (isHead ? 0.1 : 0.05))
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * (0.1 + pulseBoost * 0.05);
      canvas.drawRRect(
        fillRRect.deflate(cellSize * (0.05 - pulseBoost * 0.015)),
        border,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.gridWidth != gridWidth ||
      oldDelegate.gridHeight != gridHeight ||
      oldDelegate.glowPhase != glowPhase ||
      oldDelegate.foodPulseProgress != foodPulseProgress;
}

class _ParallaxBackground extends StatelessWidget {
  const _ParallaxBackground({required this.offset, required this.glowPhase});

  final Offset offset;
  final double glowPhase;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParallaxPainter(offset: offset, glowPhase: glowPhase),
    );
  }
}

class _ParallaxPainter extends CustomPainter {
  const _ParallaxPainter({required this.offset, required this.glowPhase});

  final Offset offset;
  final double glowPhase;

  static const List<Offset> _stars = [
    Offset(0.12, 0.18),
    Offset(0.27, 0.3),
    Offset(0.62, 0.22),
    Offset(0.78, 0.15),
    Offset(0.88, 0.38),
    Offset(0.14, 0.46),
    Offset(0.42, 0.54),
    Offset(0.68, 0.58),
    Offset(0.9, 0.65),
    Offset(0.18, 0.74),
    Offset(0.47, 0.82),
    Offset(0.72, 0.86),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [Color(0xff05070f), Color(0xff0d1424)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = baseGradient);

    final shift = Offset(
      offset.dx / max(size.width, 1.0),
      offset.dy / max(size.height, 1.0),
    );
    final highlightCenter = Alignment(
      (shift.dx * 0.8).clamp(-0.8, 0.8),
      (shift.dy * 0.8).clamp(-0.8, 0.8),
    );

    final pulse = (sin(glowPhase * 0.8) + 1) / 2;
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        center: highlightCenter,
        radius: 1.2,
        colors: [
          const Color(0xff14223f).withOpacity(0.22 + pulse * 0.12),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(rect, nebulaPaint);

    canvas.save();
    canvas.translate(offset.dx * 0.05, offset.dy * 0.05);
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff101a33).withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, wavePaint);
    canvas.restore();

    for (var i = 0; i < _stars.length; i += 1) {
      final seed = _stars[i];
      final depth = 1 + (i % 3);
      final parallax = offset * (0.015 * depth);
      final pos =
          Offset(seed.dx * size.width, seed.dy * size.height) + parallax;
      final sparkle = (sin(glowPhase * (0.6 + i * 0.12)) + 1) / 2;
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.06 * depth + sparkle * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      canvas.drawCircle(pos, (1.3 + depth * 0.7), starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParallaxPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.glowPhase != glowPhase;
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
