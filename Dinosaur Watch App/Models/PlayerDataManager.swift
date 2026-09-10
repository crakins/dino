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

    /// Call once per completed run. Returns the coin/XP bonus if this run just completed the daily quest.
    @discardableResult
    func recordQuestRun() -> (coins: Int, xp: Int)? {
        playerData.recordQuestRun()
    }

    // MARK: - Equipped Accessors

    var equippedKin: Kin {
        Kin(rawValue: playerData.equippedKin) ?? .panda
    }

    var equippedWorld: World {
        World(rawValue: playerData.equippedWorld) ?? .bambooGrove
    }

    // MARK: - Purchase Actions

    func purchase(_ kin: Kin) -> Bool {
        playerData.purchase(kin)
    }

    func purchase(_ world: World) -> Bool {
        playerData.purchase(world)
    }

    // MARK: - Equip Actions

    func equip(_ kin: Kin) {
        playerData.equip(kin)
    }

    func equip(_ world: World) {
        playerData.equip(world)
    }

    // MARK: - First-run Tips

    func markLanternRowTipSeen() {
        guard !playerData.seenLanternRowTip else { return }
        playerData.seenLanternRowTip = true
    }
}
