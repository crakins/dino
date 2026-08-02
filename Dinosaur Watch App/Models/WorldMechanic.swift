import Foundation
import CoreGraphics

/// The core input/hazard pattern a world is built around.
enum WorldMechanic {
    /// Bamboo Grove — clustered ground obstacles in a predictable tall-tall-short pattern.
    case rhythm
    /// Mist Terraces — no continuous ground; jump slab to slab across gaps in a rocky gorge.
    case elevation
    /// Snow Pass — hazards drop from above; survive by ducking, not jumping.
    case overhead
    /// Lantern Row — overhead + ground hazards on a fixed beat.
    case tempo
    /// Ash Hollow — the ground gives way underfoot if you stand still too long.
    case unstable
}

extension World {
    var mechanic: WorldMechanic {
        switch self {
        case .bambooGrove: return .rhythm
        case .mistTerraces: return .elevation
        case .snowPass: return .overhead
        case .lanternRow: return .tempo
        case .ashHollow: return .unstable
        }
    }

    /// Season-driven tuning knobs, per the design's per-world/per-season notes.
    func tuning(for season: Season) -> WorldSeasonTuning {
        switch self {
        case .bambooGrove:
            switch season {
            case .spring: return WorldSeasonTuning(scrollMultiplier: 1.0, obstacleHeightMultiplier: 0.7, shootScoreMultiplier: 2)
            case .summer: return WorldSeasonTuning(scrollMultiplier: 1.05)
            case .autumn: return WorldSeasonTuning(scrollMultiplier: 1.1)
            case .winter: return WorldSeasonTuning(scrollMultiplier: 1.15, jumpVelocityMultiplier: 1.15, gravityMultiplier: 0.85)
            }

        case .mistTerraces:
            switch season {
            case .spring: return WorldSeasonTuning(terraceHeightMultiplier: 0.6)
            case .summer: return WorldSeasonTuning(terraceHeightMultiplier: 1.8)
            case .autumn: return WorldSeasonTuning()
            case .winter: return WorldSeasonTuning(hazardSpeedMultiplier: 1.4)
            }

        case .snowPass:
            switch season {
            case .spring: return WorldSeasonTuning(obstacleHeightMultiplier: 0.7)
            case .summer: return WorldSeasonTuning(hazardDensityMultiplier: 1.3)
            case .autumn: return WorldSeasonTuning(hazardSpeedMultiplier: 1.25)
            case .winter: return WorldSeasonTuning(hazardSpeedMultiplier: 0.8, obstacleHeightMultiplier: 1.3)
            }

        case .lanternRow:
            switch season {
            case .spring: return WorldSeasonTuning(hazardDensityMultiplier: 0.7)
            case .summer: return WorldSeasonTuning(hazardDensityMultiplier: 1.6)
            case .autumn: return WorldSeasonTuning(hazardDensityMultiplier: 1.0)
            case .winter: return WorldSeasonTuning(hazardDensityMultiplier: 0.5)
            }

        case .ashHollow:
            switch season {
            case .spring: return WorldSeasonTuning(groundDecaySeconds: 2.2)
            case .summer: return WorldSeasonTuning(groundDecaySeconds: 1.0)
            case .autumn: return WorldSeasonTuning(groundDecaySeconds: 1.6)
            case .winter: return WorldSeasonTuning(groundDecaySeconds: 2.6)
            }
        }
    }
}

/// Multiplicative tuning applied on top of `GameConstants` baselines for a given (World, Season) pair.
/// Fields default to "no effect" — only the knobs a season actually calls out are set.
struct WorldSeasonTuning {
    var scrollMultiplier: CGFloat = 1.0
    /// Inversely scales spawn gaps — >1 means hazards arrive more often.
    var hazardDensityMultiplier: CGFloat = 1.0
    /// Extra closing speed for hazards that move independently of scroll (rolling stones, falling icicles).
    var hazardSpeedMultiplier: CGFloat = 1.0
    var obstacleHeightMultiplier: CGFloat = 1.0
    var jumpVelocityMultiplier: CGFloat = 1.0
    var gravityMultiplier: CGFloat = 1.0
    var terraceHeightMultiplier: CGFloat = 1.0
    var groundDecaySeconds: TimeInterval = 1.8
    var shootScoreMultiplier: Int = 1
}
