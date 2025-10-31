import 'package:flutter/material.dart';

enum ThemeUnlockType { builtIn, score, mission }

class ThemeSkin {
  const ThemeSkin({
    required this.id,
    required this.name,
    required this.palette,
    this.description,
    this.unlockType = ThemeUnlockType.builtIn,
    this.unlockValue,
  });

  final String id;
  final String name;
  final ThemePalette palette;
  final String? description;
  final ThemeUnlockType unlockType;
  final String? unlockValue;

  bool get isDefault => unlockType == ThemeUnlockType.builtIn;
}

class ThemePalette {
  const ThemePalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.snakeHead,
    required this.snakeBody,
    required this.foodGlow,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color snakeHead;
  final Color snakeBody;
  final Color foodGlow;

  ThemeData toThemeData() {
    final colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
    );
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'SF Pro Display',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );
  }
}

List<ThemeSkin> builtInThemes = [
  ThemeSkin(
    id: 'default_ocean',
    name: 'Ocean Current',
    description: 'Original palette of shimmering blues and teals.',
    palette: const ThemePalette(
      primary: Color(0xff61dbff),
      secondary: Color(0xff32e0c4),
      background: Color(0xff060913),
      surface: Color(0xff0d1324),
      snakeHead: Color(0xff61dbff),
      snakeBody: Color(0xff32e0c4),
      foodGlow: Color(0xffb388ff),
    ),
  ),
  ThemeSkin(
    id: 'emberline',
    name: 'Emberline',
    description: 'Earn 1,200 points in a single run to unlock.',
    unlockType: ThemeUnlockType.score,
    unlockValue: '1200',
    palette: const ThemePalette(
      primary: Color(0xffff6b6b),
      secondary: Color(0xfff7b267),
      background: Color(0xff1a0f0f),
      surface: Color(0xff291616),
      snakeHead: Color(0xffffad60),
      snakeBody: Color(0xffff6b6b),
      foodGlow: Color(0xffffd166),
    ),
  ),
  ThemeSkin(
    id: 'prismatic',
    name: 'Prismatic Bloom',
    description: 'Complete the mission “Absorb 6 Prism Cores” to unlock.',
    unlockType: ThemeUnlockType.mission,
    unlockValue: 'weekly_prism_6',
    palette: const ThemePalette(
      primary: Color(0xffd387ff),
      secondary: Color(0xff61dbff),
      background: Color(0xff110b1b),
      surface: Color(0xff1b1228),
      snakeHead: Color(0xffd387ff),
      snakeBody: Color(0xff6fe7ff),
      foodGlow: Color(0xfffbd6ff),
    ),
  ),
];
