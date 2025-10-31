import 'game_config.dart';
import 'grid.dart';

enum FoodEffect {
  none,
  timeSlow,
  magnet,
  laneShift,
}

enum FoodType {
  ember(
    colorHex: 0xffff6b6b,
    label: 'Ember Bloom',
    description: 'Supercharges growth but punishes repeats.',
    baseScore: 14,
    bonusGrowth: 1,
    mixBoost: 2,
    repeatPenalty: 2,
    phaseBonus: 0,
  ),
  tidal(
    colorHex: 0xff4d96ff,
    label: 'Tidal Pearl',
    description: 'Adds phase turns to slip through yourself.',
    baseScore: 16,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 1,
    phaseBonus: 2,
  ),
  gale(
    colorHex: 0xff3ad29f,
    label: 'Gale Petal',
    description: 'Keeps harmony steady and awards steady points.',
    baseScore: 12,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 0,
    phaseBonus: 0,
  ),
  prism(
    colorHex: 0xffb388ff,
    label: 'Prism Core',
    description: 'Refills harmony and grants long phasing.',
    baseScore: 32,
    bonusGrowth: 0,
    mixBoost: GameConfig.maxHarmony,
    repeatPenalty: 0,
    phaseBonus: 6,
  ),
  chrono(
    colorHex: 0xff76e5fc,
    label: 'Chrono Seed',
    description: 'Slows time for a short burst.',
    baseScore: 24,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 0,
    phaseBonus: 0,
    effect: FoodEffect.timeSlow,
    effectDuration: GameConfig.timeSlowDurationTicks,
  ),
  magnetar(
    colorHex: 0xfff7b32b,
    label: 'Magnetar Bloom',
    description: 'Pulls distant blooms into your orbit.',
    baseScore: 20,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 0,
    phaseBonus: 0,
    effect: FoodEffect.magnet,
    effectDuration: GameConfig.magnetDurationTicks,
  ),
  rift(
    colorHex: 0xfff25f5c,
    label: 'Rift Spore',
    description: 'Shifts the whole lane layout to keep you nimble.',
    baseScore: 26,
    bonusGrowth: 0,
    mixBoost: 1,
    repeatPenalty: 0,
    phaseBonus: 0,
    effect: FoodEffect.laneShift,
    effectDuration: GameConfig.laneShiftRows,
  );

  const FoodType({
    required this.colorHex,
    required this.label,
    required this.description,
    required this.baseScore,
    required this.bonusGrowth,
    required this.mixBoost,
    required this.repeatPenalty,
    required this.phaseBonus,
    this.effect = FoodEffect.none,
    this.effectDuration = 0,
  });

  final int colorHex;
  final String label;
  final String description;
  final int baseScore;
  final int bonusGrowth;
  final int mixBoost;
  final int repeatPenalty;
  final int phaseBonus;
  final FoodEffect effect;
  final int effectDuration;
}

class Food {
  const Food({required this.position, required this.type});

  final GridPosition position;
  final FoodType type;
}
