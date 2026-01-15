import SwiftUI

struct PlayerData: Codable {
    var coins: Int = 0
    var totalXP: Int = 0
    var gamesPlayed: Int = 0

    // Owned skins
    var ownedDinosaurSkins: Set<String> = [DinosaurSkin.squaresaurus.rawValue]
    var ownedObstacleSkins: Set<String> = [ObstacleSkin.cactus.rawValue]
    var ownedBackgroundSkins: Set<String> = [BackgroundSkin.desertNight.rawValue]

    // Equipped skins
    var equippedDinosaurSkin: String = DinosaurSkin.squaresaurus.rawValue
    var equippedObstacleSkin: String = ObstacleSkin.cactus.rawValue
    var equippedBackgroundSkin: String = BackgroundSkin.desertNight.rawValue

    // Daily tracking
    var lastDailyBonusDate: Double = 0

    // MARK: - Player Level

    var playerLevel: Int {
        var level = 1
        var xpNeeded = 0
        while totalXP >= xpNeeded + xpForNextLevel(level) {
            xpNeeded += xpForNextLevel(level)
            level += 1
            if level >= 20 { break }
        }
        return level
    }

    var xpInCurrentLevel: Int {
        var remaining = totalXP
        for l in 1..<playerLevel {
            remaining -= xpForNextLevel(l)
        }
        return remaining
    }

    var xpNeededForNextLevel: Int {
        xpForNextLevel(playerLevel)
    }

    private func xpForNextLevel(_ level: Int) -> Int {
        if level <= 1 { return 100 }
        return 100 + (level - 1) * 50 + max(0, (level - 2) * (level - 1) * 10)
    }

    // MARK: - Ownership Checks

    func owns(_ skin: DinosaurSkin) -> Bool {
        ownedDinosaurSkins.contains(skin.rawValue)
    }

    func owns(_ skin: ObstacleSkin) -> Bool {
        ownedObstacleSkins.contains(skin.rawValue)
    }

    func owns(_ skin: BackgroundSkin) -> Bool {
        ownedBackgroundSkins.contains(skin.rawValue)
    }

    // MARK: - Purchase Checks

    func canPurchase(_ skin: DinosaurSkin) -> Bool {
        guard !owns(skin) else { return false }
        guard coins >= skin.coinCost else { return false }
        guard playerLevel >= skin.requiredPlayerLevel else { return false }
        if let previous = skin.previousSkin {
            guard owns(previous) else { return false }
        }
        return true
    }

    func canPurchase(_ skin: ObstacleSkin) -> Bool {
        guard !owns(skin) else { return false }
        guard coins >= skin.coinCost else { return false }
        guard playerLevel >= skin.requiredPlayerLevel else { return false }
        if let previous = skin.previousSkin {
            guard owns(previous) else { return false }
        }
        return true
    }

    func canPurchase(_ skin: BackgroundSkin) -> Bool {
        guard !owns(skin) else { return false }
        guard coins >= skin.coinCost else { return false }
        guard playerLevel >= skin.requiredPlayerLevel else { return false }
        if let previous = skin.previousSkin {
            guard owns(previous) else { return false }
        }
        return true
    }

    // MARK: - Purchase Actions

    mutating func purchase(_ skin: DinosaurSkin) -> Bool {
        guard canPurchase(skin) else { return false }
        coins -= skin.coinCost
        ownedDinosaurSkins.insert(skin.rawValue)
        return true
    }

    mutating func purchase(_ skin: ObstacleSkin) -> Bool {
        guard canPurchase(skin) else { return false }
        coins -= skin.coinCost
        ownedObstacleSkins.insert(skin.rawValue)
        return true
    }

    mutating func purchase(_ skin: BackgroundSkin) -> Bool {
        guard canPurchase(skin) else { return false }
        coins -= skin.coinCost
        ownedBackgroundSkins.insert(skin.rawValue)
        return true
    }

    // MARK: - Equip Actions

    mutating func equip(_ skin: DinosaurSkin) {
        guard owns(skin) else { return }
        equippedDinosaurSkin = skin.rawValue
    }

    mutating func equip(_ skin: ObstacleSkin) {
        guard owns(skin) else { return }
        equippedObstacleSkin = skin.rawValue
    }

    mutating func equip(_ skin: BackgroundSkin) {
        guard owns(skin) else { return }
        equippedBackgroundSkin = skin.rawValue
    }
}
