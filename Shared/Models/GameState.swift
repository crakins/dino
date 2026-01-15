import SwiftUI

struct Dinosaur {
    var x: CGFloat = GameConstants.dinoX
    var y: CGFloat = 0
    var velocityY: CGFloat = 0
    var isJumping: Bool = false

    let width: CGFloat = GameConstants.dinoWidth
    let height: CGFloat = GameConstants.dinoHeight
}

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    let width: CGFloat
    let height: CGFloat

    enum ObstacleType {
        case cactusSmall
        case cactusLarge
    }

    let type: ObstacleType

    static func random(atX x: CGFloat) -> Obstacle {
        let isLarge = Bool.random()
        return Obstacle(
            x: x,
            width: isLarge ? 16 : 12,
            height: isLarge ? 28 : 20,
            type: isLarge ? .cactusLarge : .cactusSmall
        )
    }
}

enum GamePhase {
    case ready
    case countdown
    case playing
    case gameOver
}

@Observable
class GameState {
    var phase: GamePhase = .ready
    var dinosaur = Dinosaur()
    var obstacles: [Obstacle] = []
    var groundOffset: CGFloat = 0
    var score: Int = 0
    var gameSpeed: CGFloat = GameConstants.initialSpeed

    var lastObstacleSpawnDistance: CGFloat = 0
    var distanceTraveled: CGFloat = 0

    func reset() {
        phase = .ready
        dinosaur = Dinosaur()
        obstacles = []
        groundOffset = 0
        score = 0
        gameSpeed = GameConstants.initialSpeed
        lastObstacleSpawnDistance = 0
        distanceTraveled = 0
    }
}
