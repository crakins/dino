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
    @State private var lastGameReward: GameReward?

    @AppStorage("highScore") private var highScore = 0
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("lastPlayedDate") private var lastPlayedDate: Double = 0

    var body: some View {
        ZStack {
            switch gameState.phase {
            case .ready:
                MenuView(
                    highScore: highScore,
                    streak: currentStreak,
                    playerLevel: playerDataManager.playerData.playerLevel,
                    coins: playerDataManager.playerData.coins,
                    onStart: startCountdown,
                    onShop: { showShop = true },
                    onProfile: { showProfile = true }
                )
            case .countdown:
                CountdownView(onComplete: startPlaying)
            case .playing:
                GameView(
                    gameState: gameState,
                    dinosaurSkin: playerDataManager.equippedDinosaurSkin,
                    obstacleSkin: playerDataManager.equippedObstacleSkin,
                    backgroundSkin: playerDataManager.equippedBackgroundSkin
                )
            case .gameOver:
                GameOverView(
                    score: gameState.score,
                    highScore: highScore,
                    isNewHighScore: lastGameReward?.isNewHighScore ?? false,
                    streak: currentStreak,
                    reward: lastGameReward,
                    playerLevel: playerDataManager.playerData.playerLevel,
                    coins: playerDataManager.playerData.coins,
                    onRestart: startCountdown,
                    onShop: { showShop = true },
                    onProfile: { showProfile = true },
                    onHome: goToMenu
                )
            }

            if showShop {
                ShopView(
                    playerDataManager: playerDataManager,
                    onClose: { showShop = false }
                )
            }

            if showProfile {
                ProfileView(
                    playerData: playerDataManager.playerData,
                    onClose: { showProfile = false }
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
        gameState.phase = .countdown
    }

    private func startPlaying() {
        gameState.phase = .playing
    }

    private func goToMenu() {
        gameState.reset()
        gameState.phase = .ready
    }

    private func recordGameEnd() {
        let isNewHighScore = gameState.score > highScore
        if isNewHighScore {
            highScore = gameState.score
        }
        updateStreak()

        // Calculate and apply rewards
        let reward = RewardCalculator.calculate(
            score: gameState.score,
            streak: currentStreak,
            isNewHighScore: isNewHighScore,
            lastDailyBonusDate: playerDataManager.playerData.lastDailyBonusDate
        )
        playerDataManager.applyReward(reward)
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
