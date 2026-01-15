import SwiftUI
import WatchKit

struct GameEngine {
    static func update(state: GameState, deltaTime: TimeInterval, canvasSize: CGSize) {
        guard state.phase == .playing else { return }

        let dt = CGFloat(deltaTime)

        updateDinosaur(state: state, dt: dt)
        updateObstacles(state: state, dt: dt)
        spawnObstaclesIfNeeded(state: state, canvasSize: canvasSize)

        if checkCollision(state: state, canvasSize: canvasSize) {
            // Haptic feedback on collision
            WKInterfaceDevice.current().play(.failure)
            state.phase = .gameOver
            return
        }

        state.distanceTraveled += state.gameSpeed * dt
        state.score = Int(state.distanceTraveled * GameConstants.pointsPerPixel)

        state.gameSpeed = min(
            GameConstants.maxSpeed,
            state.gameSpeed + GameConstants.speedIncreaseRate * dt
        )

        state.groundOffset = state.distanceTraveled.truncatingRemainder(dividingBy: 20)
    }

    static func jump(state: GameState) {
        guard !state.dinosaur.isJumping && state.phase == .playing else { return }
        state.dinosaur.velocityY = GameConstants.jumpVelocity
        state.dinosaur.isJumping = true
    }

    private static func updateDinosaur(state: GameState, dt: CGFloat) {
        if state.dinosaur.isJumping {
            state.dinosaur.velocityY += GameConstants.gravity * dt
            state.dinosaur.y += state.dinosaur.velocityY * dt

            if state.dinosaur.y <= 0 {
                state.dinosaur.y = 0
                state.dinosaur.velocityY = 0
                state.dinosaur.isJumping = false
            }
        }
    }

    private static func updateObstacles(state: GameState, dt: CGFloat) {
        for i in state.obstacles.indices {
            state.obstacles[i].x -= state.gameSpeed * dt
        }
        state.obstacles.removeAll { $0.x < -50 }
    }

    private static func spawnObstaclesIfNeeded(state: GameState, canvasSize: CGSize) {
        let spawnX = canvasSize.width + 20
        let gapSinceLastSpawn = state.distanceTraveled - state.lastObstacleSpawnDistance
        let requiredGap = CGFloat.random(in: GameConstants.minObstacleGap...GameConstants.maxObstacleGap)

        guard gapSinceLastSpawn >= requiredGap else { return }

        state.obstacles.append(Obstacle.random(atX: spawnX))
        state.lastObstacleSpawnDistance = state.distanceTraveled
    }

    private static func checkCollision(state: GameState, canvasSize: CGSize) -> Bool {
        let groundY = canvasSize.height - GameConstants.groundOffset

        let dinoRect = CGRect(
            x: state.dinosaur.x,
            y: groundY - state.dinosaur.y - state.dinosaur.height,
            width: state.dinosaur.width,
            height: state.dinosaur.height
        ).insetBy(dx: 4, dy: 4)

        for obstacle in state.obstacles {
            let obstacleRect = CGRect(
                x: obstacle.x,
                y: groundY - obstacle.height,
                width: obstacle.width,
                height: obstacle.height
            ).insetBy(dx: 2, dy: 2)

            if dinoRect.intersects(obstacleRect) {
                return true
            }
        }

        return false
    }
}
