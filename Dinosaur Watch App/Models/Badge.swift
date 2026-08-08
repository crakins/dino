import SwiftUI

/// An achievement shown on the Den (profile). Unlock state is derived entirely from existing
/// player data — there's no separate "badges earned" persistence to keep in sync.
struct Badge: Identifiable {
    enum Icon {
        case diamond, circle, triangle, square
    }

    let id: String
    let name: String
    let description: String
    let icon: Icon
    let tint: Color
    let isUnlocked: (PlayerData, Int, Int) -> Bool // (playerData, highScore, streak)

    static let all: [Badge] = [
        Badge(id: "first-run", name: "First Steps", description: "Finish your first run.", icon: .circle, tint: PandaColor.greenPale) { data, _, _ in
            data.gamesPlayed >= 1
        },
        Badge(id: "century", name: "Century", description: "Score 100 or more in a single run.", icon: .diamond, tint: PandaColor.green) { _, highScore, _ in
            highScore >= 100
        },
        Badge(id: "half-grand", name: "Half Grand", description: "Score 500 or more in a single run.", icon: .diamond, tint: PandaColor.green) { _, highScore, _ in
            highScore >= 500
        },
        Badge(id: "thousand", name: "Four Digits", description: "Score 1000 or more in a single run.", icon: .diamond, tint: PandaColor.greenMint) { _, highScore, _ in
            highScore >= 1000
        },
        Badge(id: "streak-3", name: "Habit Forming", description: "Reach a 3-day streak.", icon: .triangle, tint: PandaColor.greenMint) { _, _, streak in
            streak >= 3
        },
        Badge(id: "streak-7", name: "One Week In", description: "Reach a 7-day streak.", icon: .triangle, tint: PandaColor.greenMint) { _, _, streak in
            streak >= 7
        },
        Badge(id: "streak-14", name: "Frostbitten", description: "Reach a 14-day streak without a single stumble.", icon: .triangle, tint: PandaColor.greenIce) { _, _, streak in
            streak >= 14
        },
        Badge(id: "marathoner", name: "Marathoner", description: "Finish 25 runs.", icon: .circle, tint: PandaColor.greenPale) { data, _, _ in
            data.gamesPlayed >= 25
        },
        Badge(id: "veteran", name: "Veteran", description: "Finish 100 runs.", icon: .circle, tint: PandaColor.green) { data, _, _ in
            data.gamesPlayed >= 100
        },
        Badge(id: "level-5", name: "Growing Up", description: "Reach level 5.", icon: .square, tint: PandaColor.greenPale) { data, _, _ in
            data.playerLevel >= 5
        },
        Badge(id: "level-10", name: "Halfway There", description: "Reach level 10.", icon: .square, tint: PandaColor.green) { data, _, _ in
            data.playerLevel >= 10
        },
        Badge(id: "level-20", name: "Max Level", description: "Reach level 20.", icon: .square, tint: PandaColor.greenMint) { data, _, _ in
            data.playerLevel >= 20
        },
        Badge(id: "reedpaw", name: "Bamboo-Fed", description: "Recruit Reedpaw.", icon: .circle, tint: PandaColor.grey) { data, _, _ in
            data.owns(.reedpaw)
        },
        Badge(id: "jadepaw", name: "Jade Collar", description: "Recruit Jadepaw.", icon: .circle, tint: PandaColor.green) { data, _, _ in
            data.owns(.jadepaw)
        },
        Badge(id: "cinderpaw", name: "Lantern-Warmed", description: "Recruit Cinderpaw.", icon: .circle, tint: PandaColor.greenDeep) { data, _, _ in
            data.owns(.cinderpaw)
        },
        Badge(id: "emberpaw", name: "Ash-Dusted", description: "Recruit Emberpaw.", icon: .circle, tint: PandaColor.greenMint) { data, _, _ in
            data.owns(.emberpaw)
        },
        Badge(id: "mist-terraces", name: "Gap Jumper", description: "Unlock Mist Terraces.", icon: .triangle, tint: PandaColor.grey) { data, _, _ in
            data.owns(.mistTerraces)
        },
        Badge(id: "snow-pass", name: "Duck and Cover", description: "Unlock Snow Pass.", icon: .triangle, tint: PandaColor.greenMint) { data, _, _ in
            data.owns(.snowPass)
        },
        Badge(id: "lantern-row", name: "Night Market", description: "Unlock Lantern Row.", icon: .triangle, tint: PandaColor.greenPale) { data, _, _ in
            data.owns(.lanternRow)
        },
        Badge(id: "ash-hollow", name: "Endgame", description: "Unlock Ash Hollow.", icon: .triangle, tint: PandaColor.white) { data, _, _ in
            data.owns(.ashHollow)
        },
        Badge(id: "collector", name: "Collector", description: "Own every Kin.", icon: .diamond, tint: PandaColor.greenMint) { data, _, _ in
            Kin.allCases.allSatisfy { data.owns($0) }
        },
        Badge(id: "wanderer", name: "Wanderer", description: "Own every World.", icon: .diamond, tint: PandaColor.greenIce) { data, _, _ in
            World.allCases.allSatisfy { data.owns($0) }
        },
        Badge(id: "wealthy", name: "Bamboo Fortune", description: "Hold 1000 coins at once.", icon: .square, tint: PandaColor.greenMint) { data, _, _ in
            data.coins >= 1000
        },
        Badge(id: "rich", name: "Bamboo Baron", description: "Hold 2500 coins at once.", icon: .square, tint: PandaColor.green) { data, _, _ in
            data.coins >= 2500
        }
    ]
}
