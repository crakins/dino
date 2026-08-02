import SwiftUI

struct PlayerData: Codable {
    var coins: Int = 0
    var totalXP: Int = 0
    var gamesPlayed: Int = 0

    // Owned Kin & Worlds
    var ownedKin: Set<String> = [Kin.panda.rawValue]
    var ownedWorlds: Set<String> = [World.bambooGrove.rawValue, World.mistTerraces.rawValue]

    // Equipped
    var equippedKin: String = Kin.panda.rawValue
    var equippedWorld: String = World.bambooGrove.rawValue

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

    func owns(_ kin: Kin) -> Bool {
        ownedKin.contains(kin.rawValue)
    }

    func owns(_ world: World) -> Bool {
        ownedWorlds.contains(world.rawValue)
    }

    // MARK: - Purchase Checks

    func canPurchase(_ kin: Kin) -> Bool {
        guard !owns(kin) else { return false }
        guard coins >= kin.coinCost else { return false }
        guard playerLevel >= kin.requiredPlayerLevel else { return false }
        if let requiredWorld = kin.requiredWorld {
            guard owns(requiredWorld) else { return false }
        }
        return true
    }

    func canPurchase(_ world: World) -> Bool {
        guard !owns(world) else { return false }
        guard coins >= world.coinCost else { return false }
        guard playerLevel >= world.requiredPlayerLevel else { return false }
        return true
    }

    // MARK: - Purchase Actions

    mutating func purchase(_ kin: Kin) -> Bool {
        guard canPurchase(kin) else { return false }
        coins -= kin.coinCost
        ownedKin.insert(kin.rawValue)
        return true
    }

    mutating func purchase(_ world: World) -> Bool {
        guard canPurchase(world) else { return false }
        coins -= world.coinCost
        ownedWorlds.insert(world.rawValue)
        return true
    }

    // MARK: - Equip Actions

    mutating func equip(_ kin: Kin) {
        guard owns(kin) else { return }
        equippedKin = kin.rawValue
    }

    mutating func equip(_ world: World) {
        guard owns(world) else { return }
        equippedWorld = world.rawValue
    }
}
