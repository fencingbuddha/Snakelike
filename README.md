# Snakelike

Chromatic Current is a cross-platform mobile twist on the classic snake formula built with Expo
and React Native. Glide through a neon grid while collecting elemental blooms to keep your
harmony meter charged. Mixing colors grants speed and scoring bonuses, while repeating the same
energy destabilises the run. Stack phase turns to slip through your own body and outmaneuver the
board as the tempo increases.

## Getting started

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Run the development server**
   ```bash
   npm run start
   ```
   Use the Expo CLI output to launch the app on iOS Simulator, Android Emulator, or an Expo Go
   device.

3. **Optional platform shortcuts**
   ```bash
   npm run ios
   npm run android
   npm run web
   ```

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
├── app.json          # Expo configuration
├── package.json      # Dependencies and scripts
├── src/
│   └── Game.tsx      # Core game loop and UI
└── tsconfig.json     # TypeScript settings
```

## Next steps

- Add sound design and haptic feedback for pickups and collisions.
- Introduce daily modifier runs with unique elemental rule sets.
- Persist high scores using Expo SecureStore or cloud sync.
