//
//  ContentView.swift
//  Dinosaur Watch App
//
//  Created by Christopher Akins on 1/9/26.
//

import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var playerDataManager = PlayerDataManager()
    @State private var showShop = false
    @State private var showProfile = false
    @State private var showQuest = false
    @State private var lastGameReward: GameReward?
    @State private var runStartTime: Date?
    @State private var runDurationSeconds: Int = 0

    @AppStorage("highScore") private var highScore = 0
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("lastPlayedDate") private var lastPlayedDate: Double = 0

    var body: some View {
        ZStack {
            switch gameState.phase {
            case .launching:
                ColdOpenView(onComplete: { gameState.phase = .ready })
            case .ready:
                MenuView(
                    highScore: highScore,
                    streak: currentStreak,
                    playerLevel: playerDataManager.playerData.playerLevel,
                    coins: playerDataManager.playerData.coins,
                    questProgress: playerDataManager.playerData.todaysQuestProgress,
                    questTarget: PlayerData.dailyQuestTarget,
                    xpFraction: xpFraction,
                    onStart: startCountdown,
                    onShop: { showShop = true },
                    onQuest: { showQuest = true },
                    onProfile: { showProfile = true }
                )
            case .countdown:
                CountdownView(season: gameState.season, onComplete: startPlaying)
            case .playing:
                GameView(gameState: gameState)
            case .gameOver:
                GameOverView(
                    score: gameState.score,
                    highScore: highScore,
                    isNewHighScore: lastGameReward?.isNewHighScore ?? false,
                    streak: currentStreak,
                    season: gameState.season,
                    runDurationSeconds: runDurationSeconds,
                    reward: lastGameReward,
                    onRestart: startCountdown,
                    onShop: { showShop = true },
                    onHome: goToMenu
                )
            }

            if showShop {
                MarketView(
                    playerDataManager: playerDataManager,
                    onClose: {
                        showShop = false
                        // Market's "Home" always means the actual Menu screen — if it was
                        // opened from Game Over, closing it should not just reveal Game Over again.
                        goToMenu()
                    }
                )
            }

            if showProfile {
                ProfileView(
                    playerData: playerDataManager.playerData,
                    highScore: highScore,
                    streak: currentStreak,
                    onClose: { showProfile = false }
                )
            }

            if showQuest {
                QuestView(
                    playerData: playerDataManager.playerData,
                    highScore: highScore,
                    onClose: { showQuest = false },
                    onRun: {
                        showQuest = false
                        startCountdown()
                    }
                )
            }
        }
        .onChange(of: gameState.phase) { _, newPhase in
            if newPhase == .gameOver {
                recordGameEnd()
            }
        }
    }

    private func startCountdown() {
        gameState.reset()
        gameState.world = playerDataManager.equippedWorld
        gameState.kinShootMultiplier = playerDataManager.equippedKin.shootScoreMultiplier
        gameState.kinEarAccent = playerDataManager.equippedKin.earAccent
        gameState.phase = .countdown
    }

    private func startPlaying() {
        runStartTime = Date()
        gameState.phase = .playing
    }

    private var xpFraction: Double {
        let data = playerDataManager.playerData
        guard data.xpNeededForNextLevel > 0 else { return 0 }
        return Double(data.xpInCurrentLevel) / Double(data.xpNeededForNextLevel)
    }

    private func goToMenu() {
        gameState.reset()
        gameState.phase = .ready
    }

    private func recordGameEnd() {
        if let runStartTime {
            runDurationSeconds = Int(Date().timeIntervalSince(runStartTime))
        }

        let isNewHighScore = gameState.score > highScore
        if isNewHighScore {
            highScore = gameState.score
        }
        updateStreak()

        // Calculate and apply rewards
        let reward = RewardCalculator.calculate(
            score: gameState.score,
            shootsCollected: gameState.shootsCollected,
            streak: currentStreak,
            isNewHighScore: isNewHighScore,
            lastDailyBonusDate: playerDataManager.playerData.lastDailyBonusDate
        )
        playerDataManager.applyReward(reward)
        playerDataManager.recordQuestRun()
        lastGameReward = reward
    }

    private func updateStreak() {
        let now = Date()
        let lastPlayed = Date(timeIntervalSince1970: lastPlayedDate)
        let calendar = Calendar.current

        if lastPlayedDate == 0 {
            currentStreak = 1
        } else if calendar.isDateInToday(lastPlayed) {
            // Already played today - no change
        } else if calendar.isDateInYesterday(lastPlayed) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        lastPlayedDate = now.timeIntervalSince1970
    }
}

#Preview {
    ContentView()
}
