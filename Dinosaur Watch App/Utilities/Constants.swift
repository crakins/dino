import SwiftUI

enum GameConstants {
    // Physics
    static let gravity: CGFloat = -800
    static let jumpVelocity: CGFloat = 280

    // Speed
    static let initialSpeed: CGFloat = 100
    static let maxSpeed: CGFloat = 250
    static let speedIncreaseRate: CGFloat = 2

    // Obstacles
    static let minObstacleGap: CGFloat = 140
    static let maxObstacleGap: CGFloat = 260
    // How much wider gaps get, proportionally, as gameSpeed rises toward maxSpeed — keeps the
    // *time* between obstacles from shrinking as distance-based gaps get covered faster.
    static let obstacleGapSpeedJitter: ClosedRange<CGFloat> = 0.85...1.3

    // Dinosaur
    static let dinoX: CGFloat = 40
    static let dinoWidth: CGFloat = 24
    static let dinoHeight: CGFloat = 28

    // Scoring
    static let pointsPerPixel: CGFloat = 0.1

    // Layout
    static let groundOffset: CGFloat = 40

    // Shoots (collectibles)
    static let minShootGap: CGFloat = 60
    static let maxShootGap: CGFloat = 140
    static let shootScoreBonus: Int = 3
    static let shootChargePerPickup: CGFloat = 9 // ~12 shoots fills the ring

    // Power-up
    static let powerUpDuration: TimeInterval = 3.0

    // Seasons
    static let seasonSegmentMeters: Int = 150
    static let seasonBannerDuration: TimeInterval = 2.5

    // World mechanics
    static let rhythmGap: CGFloat = 100
    static let tempoGap: CGFloat = 110
    static let minOverheadGap: CGFloat = 130
    static let overheadReachRange: ClosedRange<CGFloat> = 30...48
    /// Lantern Row: oversized lanterns reach further down, forcing a deeper crown-driven shrink
    /// than a normal duck — but not so far the panda can't physically get small enough to clear.
    static let extraLargeLanternReachRange: ClosedRange<CGFloat> = 52...64
    static let extraLargeLanternChance: CGFloat = 0.3
    /// How long the first-run "turn the crown" tip stays on screen in Lantern Row.
    static let lanternTipDuration: TimeInterval = 3.5
    /// How long a Snow Pass icicle takes to fall from the top of the screen into place.
    static let icicleFallDuration: TimeInterval = 0.35
    /// Spacing (in world distance) between ambient background icicles in Snow Pass.
    static let skyIcicleGap: CGFloat = 90
    /// Ambient icicles are removed once they've fallen this far past the ground line.
    static let skyIcicleMaxFall: CGFloat = 90
    static let terraceSegmentLength: CGFloat = 90
    static let terraceGapWidth: ClosedRange<CGFloat> = 26...42
}
