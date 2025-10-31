# Updated Snake Game (Flutter)

Chromatic Current is now a Flutter app with a pure Dart engine, full-screen board, and cross-platform UI. Launch it on iOS, Android, web, or desktop directly from Flutter tooling.

## Requirements

- Flutter 3.13 or newer (Dart 3)
- Xcode / Android Studio command-line tools as needed for your target platforms

## Getting Started

```bash
# Fetch dependencies
flutter pub get

# Run on an emulator or device
flutter run
```

> **Tip:** If you cloned this repository fresh, run `flutter create .` once to scaffold the `android`, `ios`, `web`, and `macos` folders before building.

The main entry point lives in `lib/main.dart`; the reusable game engine is under `lib/engine`.

## Running Tests

```bash
flutter test
```

Unit tests validate the scoring, harmony flow, food spawning, and collision rules.

## Project Structure

- `lib/engine` – Pure Dart engine (direction, food system, harmony / phase rules)
- `lib/main.dart` – Flutter UI with main menu, full-screen board, and overlays
- `test/` – Deterministic engine tests replicating gameplay scenarios
- `pubspec.yaml` – Flutter dependencies and metadata

## Gameplay Notes

- Harmony speeds up the timer; mix blooms to keep the meter high.
- Elemental blooms apply score multipliers, growth, and phase bonuses.
- Phase turns let you pass through the snake for a few moves.
- Tap the `X` at any time to retreat to the menu and restart your run.
