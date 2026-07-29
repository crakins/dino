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
}
