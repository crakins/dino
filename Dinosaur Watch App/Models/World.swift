import SwiftUI

/// A themed run world. Each world owns its hazard shape — equipping a world changes
/// what obstacles look like (and feel like) in `GameView`.
enum World: String, CaseIterable, Codable, Identifiable {
    case bambooGrove
    case mistTerraces
    case snowPass
    case lanternRow
    case ashHollow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bambooGrove: return "Bamboo Grove"
        case .mistTerraces: return "Mist Terraces"
        case .snowPass: return "Snow Pass"
        case .lanternRow: return "Lantern Row"
        case .ashHollow: return "Ash Hollow"
        }
    }

    var shortName: String { displayName }

    var hazardName: String {
        switch self {
        case .bambooGrove: return "BAMBOO STALKS"
        case .mistTerraces: return "GAPS TO CLEAR"
        case .snowPass: return "FALLING ICICLES"
        case .lanternRow: return "SWINGING LANTERNS"
        case .ashHollow: return "SHIFTING SCREE"
        }
    }

    /// Worlds unlock either by coins or by player level, never both.
    var coinCost: Int {
        switch self {
        case .snowPass: return 200
        default: return 0
        }
    }

    var requiredPlayerLevel: Int {
        switch self {
        case .lanternRow: return 9
        case .ashHollow: return 14
        default: return 1
        }
    }

    var ownedByDefault: Bool {
        self == .bambooGrove || self == .mistTerraces
    }

    var accentColor: Color {
        switch self {
        case .bambooGrove: return PandaColor.green
        case .mistTerraces: return PandaColor.grey
        case .snowPass: return PandaColor.greenMint
        case .lanternRow: return PandaColor.white
        case .ashHollow: return PandaColor.white
        }
    }
}
