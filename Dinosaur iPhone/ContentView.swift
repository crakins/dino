import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var playerDataManager = PlayerDataManager()

    @AppStorage("highScore") private var highScore = 0
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("lastPlayedDate") private var lastPlayedDate: Double = 0

    @State private var showShop = false
    @State private var showProfile = false
    @State private var lastGameReward: GameReward?

    // Get equipped skins
    private var equippedDinosaurSkin: DinosaurSkin {
        DinosaurSkin(rawValue: playerDataManager.playerData.equippedDinosaurSkin) ?? .squaresaurus
    }

    private var equippedObstacleSkin: ObstacleSkin {
        ObstacleSkin(rawValue: playerDataManager.playerData.equippedObstacleSkin) ?? .cactus
    }

    private var equippedBackgroundSkin: BackgroundSkin {
        BackgroundSkin(rawValue: playerDataManager.playerData.equippedBackgroundSkin) ?? .desertNight
    }

    var body: some View {
        ZStack {
            switch gameState.phase {
            case .ready:
                iPhoneMenuView(
                    highScore: highScore,
                    streak: currentStreak,
                    playerLevel: playerDataManager.playerData.playerLevel,
                    coins: playerDataManager.playerData.coins,
                    onStart: { gameState.phase = .countdown },
                    onShop: { showShop = true },
                    onProfile: { showProfile = true }
                )

            case .countdown:
                iPhoneCountdownView {
                    startGame()
                }

            case .playing:
                iPhoneGameView(
                    gameState: gameState,
                    dinosaurSkin: equippedDinosaurSkin,
                    obstacleSkin: equippedObstacleSkin,
                    backgroundSkin: equippedBackgroundSkin
                )

            case .gameOver:
                iPhoneGameOverView(
                    score: gameState.score,
                    highScore: highScore,
                    isNewHighScore: gameState.score > highScore,
                    streak: currentStreak,
                    reward: lastGameReward,
                    playerLevel: playerDataManager.playerData.playerLevel,
                    coins: playerDataManager.playerData.coins,
                    onRestart: { gameState.phase = .countdown },
                    onShop: { showShop = true },
                    onProfile: { showProfile = true },
                    onHome: { gameState.phase = .ready }
                )
            }
        }
        .sheet(isPresented: $showShop) {
            iPhoneShopView(playerDataManager: playerDataManager) {
                showShop = false
            }
        }
        .sheet(isPresented: $showProfile) {
            iPhoneProfileView(playerDataManager: playerDataManager) {
                showProfile = false
            }
        }
        .onChange(of: gameState.phase) { oldPhase, newPhase in
            if oldPhase == .playing && newPhase == .gameOver {
                recordGameEnd()
            }
        }
    }

    private func startGame() {
        gameState.reset()
        gameState.phase = .playing
    }

    private func recordGameEnd() {
        let score = gameState.score
        let isNewHighScore = score > highScore

        if isNewHighScore {
            highScore = score
        }

        // Update streak
        let today = Calendar.current.startOfDay(for: Date())
        let lastPlayed = Date(timeIntervalSince1970: lastPlayedDate)
        let lastPlayedDay = Calendar.current.startOfDay(for: lastPlayed)

        let daysSinceLastPlay = Calendar.current.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0

        let isFirstGameOfDay: Bool
        if daysSinceLastPlay == 0 {
            isFirstGameOfDay = false
        } else if daysSinceLastPlay == 1 {
            currentStreak += 1
            isFirstGameOfDay = true
        } else {
            currentStreak = 1
            isFirstGameOfDay = true
        }

        lastPlayedDate = today.timeIntervalSince1970

        // Calculate rewards
        let reward = RewardCalculator.calculate(
            score: score,
            isNewHighScore: isNewHighScore,
            streak: currentStreak,
            isFirstGameOfDay: isFirstGameOfDay
        )

        lastGameReward = reward

        // Apply rewards
        playerDataManager.addCoins(reward.totalCoins)
        playerDataManager.addXP(reward.totalXP)
        playerDataManager.incrementGamesPlayed()
    }
}
