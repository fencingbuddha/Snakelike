# Updated Snake Game (SwiftUI)

Native SwiftUI rewrite of the Chromatic Current snake adventure. The project is ready to run and test entirely inside Xcode, with a pure Swift game engine that mirrors the original gameplay systems.

## Requirements

- Xcode 15 or newer (tested with iOS 16+ simulators)
- macOS Ventura or newer recommended

## Getting Started

1. Open `iOS/UpdatedSnakeGame.xcodeproj` in Xcode.
2. Select the `UpdatedSnakeGame` scheme and an iOS simulator or a connected device.
3. Build & run (`⌘R`) to launch the game.
4. Tap the `X` in the upper-right corner to return to the main menu at any time.

## Running Tests

Unit tests cover the snake engine, food system, harmony rules, and collision logic.

```bash
# From Xcode: Product ▸ Test (⌘U)
```

The `UpdatedSnakeGame` engine lives under `iOS/UpdatedSnakeGame/Engine` and can be tested independently from the SwiftUI interface.

## Project Structure

- `iOS/UpdatedSnakeGame.xcodeproj` – Xcode project configured with app and test targets.
- `iOS/UpdatedSnakeGame` – SwiftUI app sources, assets, and Info.plist.
- `iOS/UpdatedSnakeGame/Engine` – Pure Swift gameplay logic for easier testing.
- `iOS/UpdatedSnakeGameTests` – XCTest bundle with deterministic engine checks.

## Gameplay Notes

- Harmony increases the snake's speed; mixing different blooms keeps the flow going.
- Elemental blooms grant unique bonuses (growth, phase turns, harmony refill).
- Phase turns let the snake slip through itself for a limited number of moves.
- A full-screen board keeps the action front and center; use the exit button any time to re-enter the chromatic calm of the menu.

Enjoy weaving your chromatic current natively in Xcode!
