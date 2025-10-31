class GameConfig {
  static const int gridWidth = 18;
  static const int minGridHeight = 18;
  static const int minHarmony = 0;
  static const int maxHarmony = 6;
  static const int maxPhaseTurns = 12;

  static const int baseTickMilliseconds = 230;
  static const int tickHarmonyReduction = 25;
  static const int minTickMilliseconds = 80;
  static const double timeSlowMultiplier = 1.6;
  static const int timeSlowDurationTicks = 18;
  static const int magnetDurationTicks = 20;
  static const int magnetRadius = 4;
  static const int laneShiftRows = 1;

  static const int hazardLifetimeTicks = 28;
  static const int hazardSpawnInterval = 10;
  static const int initialHazardCooldown = 6;
  static const int harmonyDifficultyThreshold = 4;
  static const int maxHazards = 6;
  static const int maxDifficultyLevel = 5;
}
