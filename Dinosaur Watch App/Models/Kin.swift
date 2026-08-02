import SwiftUI

/// A panda evolution stage. Kin are cosmetic except where a perk is noted —
/// only Jadepaw currently carries an active gameplay multiplier.
enum Kin: String, CaseIterable, Codable, Identifiable {
    case panda
    case reedpaw
    case jadepaw
    case cinderpaw
    case emberpaw

    var id: String { rawValue }

    var stage: Int {
        switch self {
        case .panda: return 1
        case .reedpaw: return 2
        case .jadepaw: return 3
        case .cinderpaw: return 4
        case .emberpaw: return 5
        }
    }

    var displayName: String {
        switch self {
        case .panda: return "Panda"
        case .reedpaw: return "Reedpaw"
        case .jadepaw: return "Jadepaw"
        case .cinderpaw: return "Cinderpaw"
        case .emberpaw: return "Emberpaw"
        }
    }

    var tagline: String {
        switch self {
        case .panda: return "Your very own panda. Runs, jumps, no frills yet."
        case .reedpaw: return "Bamboo-fed and quick on the reeds."
        case .jadepaw: return "Jade collar. Shoots are worth double while the grove holds."
        case .cinderpaw: return "Lantern-warmed fur, steady in the dark rows."
        case .emberpaw: return "Ash-dusted and unbothered by the scree."
        }
    }

    var earAccent: Color {
        switch self {
        case .panda: return PandaColor.pandaBlack
        case .reedpaw: return PandaColor.grey
        case .jadepaw: return PandaColor.green
        case .cinderpaw: return PandaColor.greenDeep
        case .emberpaw: return PandaColor.greenMint
        }
    }

    /// The world that must be owned before this stage can be recruited.
    var requiredWorld: World? {
        switch self {
        case .panda: return nil
        case .reedpaw: return .bambooGrove
        case .jadepaw: return .snowPass
        case .cinderpaw: return .lanternRow
        case .emberpaw: return .ashHollow
        }
    }

    var requiredPlayerLevel: Int {
        switch self {
        case .panda: return 1
        case .reedpaw: return 3
        case .jadepaw: return 6
        case .cinderpaw: return 9
        case .emberpaw: return 14
        }
    }

    var coinCost: Int {
        switch self {
        case .panda: return 0
        case .reedpaw: return 80
        case .jadepaw: return 300
        case .cinderpaw: return 450
        case .emberpaw: return 650
        }
    }

    /// Score multiplier applied to shoot pickups while this Kin is equipped.
    var shootScoreMultiplier: Int {
        self == .jadepaw ? 2 : 1
    }

    var perkTag: String? {
        shootScoreMultiplier > 1 ? "×\(shootScoreMultiplier) SHOOTS" : nil
    }
}
