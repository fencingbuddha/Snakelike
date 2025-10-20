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
   - Plug the phone into your Mac with a Lightning/USB-C cable, unlock it, and tap **Trust** when
     prompted. On iOS 16+, also enable **Developer Mode** under *Settings → Privacy & Security*.
   - Open `ios/Snakelike.xcworkspace` in Xcode, pick your device from the scheme selector, and set
     your Apple developer team in **Signing & Capabilities** the first time you run.
   - Press the **Run ▶︎** button. Xcode will build the native bundle, launch Metro automatically, and
     install the app on the device. Subsequent JavaScript edits hot-reload through Metro.
   - Prefer the terminal? Leave Xcode closed and run
     ```bash
     npm run ios -- --device "Your iPhone Name"
     ```
     This uses the React Native CLI (requires Xcode command-line tools) to build and install the app
     directly after Metro starts. The device name must match `xcrun xctrace list devices` output.

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
