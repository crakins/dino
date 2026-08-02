import SwiftUI

struct Dinosaur {
    var x: CGFloat = GameConstants.dinoX
    var y: CGFloat = 0
    var velocityY: CGFloat = 0
    var isJumping: Bool = false
    var isDucking: Bool = false
    var duckTimeRemaining: TimeInterval = 0

    let width: CGFloat = GameConstants.dinoWidth
    let height: CGFloat = GameConstants.dinoHeight

    /// Effective collision height right now — compressed while ducking (Snow Pass / Lantern Row).
    var currentHeight: CGFloat {
        isDucking ? height * 0.5 : height
    }
}

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat
    let height: CGFloat
    /// Extra closing speed beyond world scroll — used for Mist Terraces' rolling stones.
    var speedMultiplier: CGFloat = 1.0

    enum ObstacleType {
        case bambooShort
        case bambooMedium
        case bambooTall
    }

    let type: ObstacleType

    static func random(atX x: CGFloat, heightMultiplier: CGFloat = 1.0) -> Obstacle {
        let type = ObstacleType.allCases.randomElement()!
        return Obstacle(x: x, width: type.width, height: type.height * heightMultiplier, type: type)
    }

    static func rhythm(atX x: CGFloat, type: ObstacleType, heightMultiplier: CGFloat = 1.0) -> Obstacle {
        Obstacle(x: x, width: type.width, height: type.height * heightMultiplier, type: type)
    }
}

extension Obstacle.ObstacleType: CaseIterable {
    var width: CGFloat {
        switch self {
        case .bambooShort: return 5
        case .bambooMedium: return 5
        case .bambooTall: return 6
        }
    }

    var height: CGFloat {
        switch self {
        case .bambooShort: return 19
        case .bambooMedium: return 24
        case .bambooTall: return 34
        }
    }
}

/// A hazard that hangs from the top of the screen — survive by ducking, not jumping.
/// Used by Snow Pass (icicles) and Lantern Row (lanterns).
struct OverheadHazard: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat
    /// How far down from the top of the play area this hazard reaches.
    let reach: CGFloat

    static func random(atX x: CGFloat, reachRange: ClosedRange<CGFloat>) -> OverheadHazard {
        OverheadHazard(x: x, width: 8, reach: CGFloat.random(in: reachRange))
    }
}

/// A stepped ground segment — Mist Terraces' elevation changes.
struct Terrace: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat
    /// Positive = ground is higher here (dino stands further up the screen).
    let heightOffset: CGFloat
}

struct Shoot: Identifiable {
    let id = UUID()
    var x: CGFloat
    /// Height above the ground line, in points.
    let groundHeight: CGFloat
    let radius: CGFloat

    static func random(atX x: CGFloat) -> Shoot {
        Shoot(x: x, groundHeight: CGFloat.random(in: 18...50), radius: Bool.random() ? 3.5 : 3)
    }
}

enum Season: Int, CaseIterable {
    case spring, summer, autumn, winter

    var displayName: String {
        switch self {
        case .spring: return "SPRING"
        case .summer: return "SUMMER"
        case .autumn: return "AUTUMN"
        case .winter: return "WINTER"
        }
    }

    var accentColor: Color {
        switch self {
        case .spring: return PandaColor.greenPale
        case .summer: return PandaColor.green
        case .autumn: return PandaColor.greenDeep
        case .winter: return PandaColor.greenIce
        }
    }
}

enum GamePhase {
    case launching
    case ready
    case countdown
    case playing
    case gameOver
}

@Observable
class GameState {
    var phase: GamePhase = .launching
    var world: World = .bambooGrove
    var dinosaur = Dinosaur()
    var obstacles: [Obstacle] = []
    var groundOffset: CGFloat = 0
    var score: Int = 0
    var gameSpeed: CGFloat = GameConstants.initialSpeed

    var lastObstacleSpawnDistance: CGFloat = 0
    var distanceTraveled: CGFloat = 0

    // Rhythm (Bamboo Grove): a repeating tall-tall-short cluster pattern.
    var rhythmPatternIndex: Int = 0
    static let rhythmPattern: [Obstacle.ObstacleType] = [.bambooTall, .bambooTall, .bambooShort]

    // Overhead hazards (Snow Pass, Lantern Row)
    var overheadHazards: [OverheadHazard] = []
    var lastOverheadSpawnDistance: CGFloat = 0

    // Elevation (Mist Terraces)
    var terraces: [Terrace] = []
    var currentTerraceHeight: CGFloat = 0
    /// True when the dinosaur's x position has no platform beneath it — a gap in Mist Terraces.
    var isOverGap: Bool = false

    // Ground stability (Ash Hollow) — depletes while grounded, resets on jump.
    var groundStability: CGFloat = 1.0

    // Shoots & combo
    var shoots: [Shoot] = []
    var lastShootSpawnDistance: CGFloat = 0
    var shootsCollected: Int = 0
    var kinShootMultiplier: Int = 1
    var kinEarAccent: Color = PandaColor.pandaBlack

    // Power-up charge
    var powerCharge: CGFloat = 0 // 0...100
    var powerUpActive: Bool = false
    var powerUpTimeRemaining: TimeInterval = 0

    // Season
    var lastSeasonIndex: Int = 0
    var seasonBannerVisibleUntil: Date?

    var metersTraveled: Int {
        Int(distanceTraveled / 10)
    }

    var season: Season {
        Season.allCases[(metersTraveled / GameConstants.seasonSegmentMeters) % Season.allCases.count]
    }

    var seasonSegmentProgress: CGFloat {
        let into = CGFloat(metersTraveled % GameConstants.seasonSegmentMeters)
        return into / CGFloat(GameConstants.seasonSegmentMeters)
    }

    var tuning: WorldSeasonTuning {
        world.tuning(for: season)
    }

    func reset() {
        phase = .ready
        dinosaur = Dinosaur()
        obstacles = []
        groundOffset = 0
        score = 0
        gameSpeed = GameConstants.initialSpeed
        lastObstacleSpawnDistance = 0
        distanceTraveled = 0
        rhythmPatternIndex = 0
        overheadHazards = []
        lastOverheadSpawnDistance = 0
        terraces = []
        currentTerraceHeight = 0
        isOverGap = false
        groundStability = 1.0
        shoots = []
        lastShootSpawnDistance = 0
        shootsCollected = 0
        powerCharge = 0
        powerUpActive = false
        powerUpTimeRemaining = 0
        lastSeasonIndex = 0
        seasonBannerVisibleUntil = nil
    }
}
