# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

watchOS endless runner game (like Chrome's dinosaur game) built with SwiftUI targeting watchOS 11.4+. Includes gamification with coins, XP levels, and evolution-style skin unlocks.

## Build Commands

This is an Xcode project. Build and run using:
- **Build**: `xcodebuild -scheme "Dinosaur Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'`
- **Run**: Open `Dinosaur.xcodeproj` in Xcode and use Cmd+R

## Architecture

Two-target structure:
- **Dinosaur** - Container target
- **Dinosaur Watch App** - Main watch app (bundle: `com.a6enterprises.Dinosaur.watchkitapp`)

### Source Structure

```
Dinosaur Watch App/
├── DinosaurApp.swift          # App entry point
├── ContentView.swift          # Game phase state machine, PlayerDataManager
├── Models/
│   ├── GameState.swift        # @Observable game state (dinosaur, obstacles, score)
│   ├── PlayerProfile.swift    # Skin enums (DinosaurSkin, ObstacleSkin, BackgroundSkin)
│   ├── PlayerData.swift       # Player data struct (coins, XP, owned/equipped skins)
│   ├── PlayerDataManager.swift # @Observable manager with UserDefaults persistence
│   └── RewardCalculator.swift # Coin/XP earning formulas
├── Engine/
│   └── GameEngine.swift       # Physics, collision, spawning logic
├── Views/
│   ├── GameView.swift         # TimelineView + Canvas rendering with skin support
│   ├── MenuView.swift         # Start screen with shop/profile buttons
│   ├── GameOverView.swift     # Score + rewards display
│   ├── ProfileView.swift      # Player level, XP bar, stats
│   └── Shop/
│       └── ShopView.swift     # Skin shop with evolution chains
└── Utilities/
    └── Constants.swift        # Physics tuning parameters
```

### Key Patterns

- **Rendering**: `TimelineView(.animation)` + `Canvas` for smooth 60fps game loop
- **State**: `@Observable` class (Swift Observation framework) for reactive state
- **Persistence**: `@AppStorage` for scores/streaks, `UserDefaults` JSON for player data
- **Input**: `DragGesture(minimumDistance: 0)` with `@GestureState` for instant tap response

### Game Flow

`ContentView` manages three phases via `GameState.phase`:
1. `.ready` → MenuView (tap to start, shop/profile buttons)
2. `.playing` → GameView (game loop with equipped skins)
3. `.gameOver` → GameOverView (score + coins/XP earned)

### Gamification System

**Currency**: Coins earned per game = `score/10 + bonuses`
- Score milestones: +5/+15/+30/+50 at 100/200/500/1000
- Streak bonus: +10-30% for 3-14+ day streaks
- First game of day: +10 coins

**XP/Levels**: XP earned per game = `score/5 + bonuses`
- Player levels 1-20 gate which skins can be purchased
- Level requirements increase progressively

**Evolution Skins**: Must own previous level to buy next
- Dinosaur: Squaresaurus → Spike → Chrome → Mech-Rex → Dragon
- Obstacles: Cactus → Crystal → Lava Rock
- Backgrounds: Desert Night → Neon City → Volcano

### Physics Constants (in Constants.swift)

Tune these values to adjust game feel:
- `gravity`: -800 (jump arc)
- `jumpVelocity`: 280 (jump height)
- `initialSpeed`/`maxSpeed`: 100-250 (obstacle speed)
- `minObstacleGap`/`maxObstacleGap`: 120-200 (spawn frequency)
