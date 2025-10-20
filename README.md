# Snakelike

Chromatic Current is a cross-platform mobile twist on the classic snake formula powered by the
React Native CLI. Glide through a neon grid while collecting elemental blooms to keep your harmony
meter charged. Mixing colors grants speed and scoring bonuses, while repeating the same energy
destabilises the run. Stack phase turns to slip through your own body and outmaneuver the board as
the tempo increases.

## Native setup (no Expo)

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Generate native scaffolding** – copies the stock iOS/Android projects from the React Native
   template into this repository. Run this once or whenever you need to regenerate the platform
   folders.
   ```bash
   npm run bootstrap:native
   ```

3. **Install iOS pods** – Requires the CocoaPods toolchain (`sudo gem install cocoapods` if you
   don't already have it).
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Start Metro**
   ```bash
   npm run start
   ```

5. **Run on a cabled iPhone**
   - Connect your device via USB and trust the computer.
   - Open `ios/Snakelike.xcworkspace` in Xcode, select your phone as the run target, assign your
     Apple developer team under **Signing & Capabilities**, then press **Run**.
   - Alternatively, from the terminal you can run
     ```bash
     npm run ios -- --device "Your iPhone Name"
     ```
     (requires Xcode Command Line Tools).

6. **Android (optional)** – With the Android SDK installed, you can launch an emulator or connected
   device via `npm run android` after completing step 2.

## Gameplay overview

- **Harmony meter** – Eating different colors back-to-back fills the meter, rewarding higher
  scores and faster ticks. Repeating a color drains harmony; lose it all and the board speed will
  stagnate, making survival tougher.
- **Elemental blooms** – Each pickup carries a unique perk:
  - *Ember Bloom* supercharges growth but harshly penalises repeats.
  - *Tidal Pearl* grants phase turns, letting you pass safely through yourself for a limited time.
  - *Gale Petal* offers steady scoring without destabilising harmony.
  - *Prism Core* is rare, instantly refilling harmony and gifting an extended phasing window.
- **Swipe controls** – Swipe across the board to set the next direction. Opposite turns are
  prevented to avoid instant collisions.
- **Restart quickly** – On a harmony collapse, tap **Restart Run** to jump straight back in.

## Project structure

```
.
├── App.tsx           # App entry point
├── app.json          # App name metadata for React Native CLI
├── package.json      # Dependencies, Metro/Jest config, and RN scripts
├── scripts/
│   └── bootstrap-native.js # Copies stock ios/android templates from react-native
├── src/
│   └── Game.tsx      # Core game loop and UI
└── tsconfig.json     # TypeScript settings
```

## Next steps

- Add sound design and haptic feedback for pickups and collisions.
- Introduce daily modifier runs with unique elemental rule sets.
- Persist high scores using a native keychain/Keystore wrapper or cloud sync.
