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
    static let minObstacleGap: CGFloat = 120
    static let maxObstacleGap: CGFloat = 200

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
    static let duckDuration: TimeInterval = 0.55
    static let rhythmGap: CGFloat = 100
    static let tempoGap: CGFloat = 110
    static let minOverheadGap: CGFloat = 130
    static let overheadReachRange: ClosedRange<CGFloat> = 30...48
    static let terraceSegmentLength: CGFloat = 90
    static let terraceGapWidth: ClosedRange<CGFloat> = 26...42
}
