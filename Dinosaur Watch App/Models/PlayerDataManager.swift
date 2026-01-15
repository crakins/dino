import SwiftUI

@Observable
class PlayerDataManager {
    private let storageKey = "playerData"

    var playerData: PlayerData {
        didSet {
            save()
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PlayerData.self, from: data) {
            self.playerData = decoded
        } else {
            self.playerData = PlayerData()
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(playerData) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Reward Application

    func applyReward(_ reward: GameReward) {
        playerData.coins += reward.totalCoins
        playerData.totalXP += reward.totalXP
        playerData.gamesPlayed += 1
        if reward.isFirstGameOfDay {
            playerData.lastDailyBonusDate = Date().timeIntervalSince1970
        }
    }

    // MARK: - Equipped Skin Accessors

    var equippedDinosaurSkin: DinosaurSkin {
        DinosaurSkin(rawValue: playerData.equippedDinosaurSkin) ?? .squaresaurus
    }

    var equippedObstacleSkin: ObstacleSkin {
        ObstacleSkin(rawValue: playerData.equippedObstacleSkin) ?? .cactus
    }

    var equippedBackgroundSkin: BackgroundSkin {
        BackgroundSkin(rawValue: playerData.equippedBackgroundSkin) ?? .desertNight
    }

    // MARK: - Purchase Actions

    func purchase(_ skin: DinosaurSkin) -> Bool {
        playerData.purchase(skin)
    }

    func purchase(_ skin: ObstacleSkin) -> Bool {
        playerData.purchase(skin)
    }

    func purchase(_ skin: BackgroundSkin) -> Bool {
        playerData.purchase(skin)
    }

    // MARK: - Equip Actions

    func equip(_ skin: DinosaurSkin) {
        playerData.equip(skin)
    }

    func equip(_ skin: ObstacleSkin) {
        playerData.equip(skin)
    }

    func equip(_ skin: BackgroundSkin) {
        playerData.equip(skin)
    }
}
