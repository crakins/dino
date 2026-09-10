import SwiftUI
import WatchKit

struct GameEngine {
    static func update(state: GameState, deltaTime: TimeInterval, canvasSize: CGSize) {
        guard state.phase == .playing else { return }

        let dt = CGFloat(deltaTime)
        let tuning = state.tuning
        let speed = state.gameSpeed * tuning.scrollMultiplier

        // Terraces move (and isOverGap is recomputed) before the dinosaur's physics step, so a
        // landing this frame can see whether a platform has actually arrived underneath yet.
        updateTerraces(state: state, dt: dt, speed: speed)
        updateDinosaur(state: state, dt: dt, tuning: tuning)
        updateObstacles(state: state, dt: dt, speed: speed)
        updateOverheadHazards(state: state, dt: dt, speed: speed)
        updateSkyIcicles(state: state, dt: dt, speed: speed)
        updateShoots(state: state, dt: dt, speed: speed, canvasSize: canvasSize)
        updatePowerUp(state: state, dt: deltaTime)
        updateGroundStability(state: state, dt: deltaTime, tuning: tuning)

        spawnObstaclesIfNeeded(state: state, canvasSize: canvasSize, tuning: tuning)
        spawnOverheadIfNeeded(state: state, canvasSize: canvasSize, tuning: tuning)
        spawnTerracesIfNeeded(state: state, canvasSize: canvasSize, tuning: tuning)
        spawnShootsIfNeeded(state: state, canvasSize: canvasSize)
        spawnSkyIciclesIfNeeded(state: state, canvasSize: canvasSize)

        let hitObstacle = checkObstacleCollision(state: state, canvasSize: canvasSize)
        let hitOverhead = checkOverheadCollision(state: state, canvasSize: canvasSize)
        let groundGaveWay = state.world.mechanic == .unstable && state.groundStability <= 0 && !state.dinosaur.isJumping

        // Walked (not jumped) into a gap — no way to recover, but rather than end the run the
        // instant a foot leaves the ledge, let gravity take over so the panda visibly tips off
        // the edge and falls out of frame before the run actually ends.
        if state.world.mechanic == .elevation && state.isOverGap && !state.dinosaur.isJumping {
            state.dinosaur.isJumping = true
            state.dinosaur.velocityY = 0
            state.isFallingToDeath = true
        }
        // Either a walk-off-the-ledge fall or a jump whose arc carried past every platform in
        // reach — genuinely missed the landing and has fallen far enough to vanish off-screen.
        let missedLanding = state.world.mechanic == .elevation && state.dinosaur.isJumping && state.dinosaur.y < -70

        if (hitObstacle || hitOverhead || groundGaveWay || missedLanding) && !state.powerUpActive {
            WKInterfaceDevice.current().play(.failure)
            state.phase = .gameOver
            return
        }

        state.distanceTraveled += speed * dt
        state.score = Int(state.distanceTraveled * GameConstants.pointsPerPixel)

        state.gameSpeed = min(
            GameConstants.maxSpeed,
            state.gameSpeed + GameConstants.speedIncreaseRate * dt
        )

        state.groundOffset = state.distanceTraveled.truncatingRemainder(dividingBy: 20)

        updateSeasonBanner(state: state)
    }

    static func jump(state: GameState) {
        guard !state.dinosaur.isJumping, !state.dinosaur.isDucking, state.phase == .playing else { return }
        let tuning = state.tuning
        state.dinosaur.velocityY = GameConstants.jumpVelocity * tuning.jumpVelocityMultiplier
        state.dinosaur.isJumping = true
        state.groundStability = 1.0 // fresh footing once airborne
    }

    /// Live-updates how small the panda is from the Digital Crown position — called continuously
    /// as the crown turns, not just once on a threshold crossing, so the player can dial in
    /// exactly how far to shrink for a normal lantern versus an extra-large one.
    static func setDuckLevel(state: GameState, level: CGFloat) {
        guard state.phase == .playing, !state.dinosaur.isJumping else { return }
        state.dinosaur.duckLevel = max(0, min(1, level))
    }

    static func activatePowerUp(state: GameState) {
        guard state.phase == .playing, state.powerCharge >= 100, !state.powerUpActive else { return }
        state.powerUpActive = true
        state.powerUpTimeRemaining = GameConstants.powerUpDuration
        state.powerCharge = 0
        WKInterfaceDevice.current().play(.start)
    }

    // MARK: - Per-frame updates

    private static func updateDinosaur(state: GameState, dt: CGFloat, tuning: WorldSeasonTuning) {
        if state.dinosaur.isJumping {
            state.dinosaur.velocityY += GameConstants.gravity * tuning.gravityMultiplier * dt
            state.dinosaur.y += state.dinosaur.velocityY * dt

            // Over a Mist Terraces gap, keep falling past y=0 instead of snapping to a ground
            // that isn't there yet — the jump only ends once an actual platform is underneath.
            // Once a fatal fall has begun, ignore any ledge that scrolls in underneath too —
            // the run is already over, so the panda should keep falling out of frame rather
            // than "land" on it and let the player carry on.
            let overGap = state.world.mechanic == .elevation && (state.isOverGap || state.isFallingToDeath)
            if state.dinosaur.y <= 0 && !overGap {
                state.dinosaur.y = 0
                state.dinosaur.velocityY = 0
                state.dinosaur.isJumping = false
            }
        }

        // Jumping overrides any shrink in progress — can't jump while scrunched down.
        if state.dinosaur.isJumping && state.dinosaur.duckLevel > 0 {
            state.dinosaur.duckLevel = 0
        }
    }

    private static func updateObstacles(state: GameState, dt: CGFloat, speed: CGFloat) {
        for i in state.obstacles.indices {
            state.obstacles[i].x -= speed * dt * state.obstacles[i].speedMultiplier
            if state.obstacles[i].fallProgress < 1 {
                state.obstacles[i].fallProgress = min(1, state.obstacles[i].fallProgress + dt / GameConstants.icicleFallDuration)
            }
        }
        state.obstacles.removeAll { $0.x < -50 }
    }

    private static func updateSkyIcicles(state: GameState, dt: CGFloat, speed: CGFloat) {
        guard state.world.mechanic == .overhead else { return }
        for i in state.skyIcicles.indices {
            state.skyIcicles[i].y += state.skyIcicles[i].velocityY * dt
        }
        state.skyIcicles.removeAll { $0.y > GameConstants.skyIcicleMaxFall }
    }

    private static func updateOverheadHazards(state: GameState, dt: CGFloat, speed: CGFloat) {
        for i in state.overheadHazards.indices {
            state.overheadHazards[i].x -= speed * dt
        }
        state.overheadHazards.removeAll { $0.x < -20 }
    }

    private static func updateTerraces(state: GameState, dt: CGFloat, speed: CGFloat) {
        guard state.world.mechanic == .elevation else { return }
        // Terraces haven't spawned yet on the very first frame — nothing to fall through yet.
        guard !state.terraces.isEmpty else { return }

        for i in state.terraces.indices {
            state.terraces[i].x -= speed * dt
        }
        state.terraces.removeAll { $0.x + $0.width < -20 }

        let dinoX = state.dinosaur.x
        if let current = state.terraces.first(where: { $0.x <= dinoX && dinoX <= $0.x + $0.width }) {
            state.currentTerraceHeight = current.heightOffset
            state.isOverGap = false
        } else {
            state.isOverGap = true
        }
    }

    private static func updateGroundStability(state: GameState, dt: TimeInterval, tuning: WorldSeasonTuning) {
        guard state.world.mechanic == .unstable, !state.dinosaur.isJumping else { return }
        state.groundStability -= dt / tuning.groundDecaySeconds
    }

    private static func updateShoots(state: GameState, dt: CGFloat, speed: CGFloat, canvasSize: CGSize) {
        for i in state.shoots.indices {
            state.shoots[i].x -= speed * dt
        }

        let groundY = canvasSize.height - GameConstants.groundOffset - state.currentTerraceHeight
        let dinoRect = CGRect(
            x: state.dinosaur.x,
            y: groundY - state.dinosaur.y - state.dinosaur.currentHeight,
            width: state.dinosaur.width,
            height: state.dinosaur.currentHeight
        )

        var collectedIndices: [Int] = []
        for (i, shoot) in state.shoots.enumerated() {
            let shootRect = CGRect(
                x: shoot.x - shoot.radius,
                y: groundY - shoot.groundHeight - shoot.radius,
                width: shoot.radius * 2,
                height: shoot.radius * 2
            )
            if dinoRect.intersects(shootRect) {
                collectedIndices.append(i)
            }
        }

        if !collectedIndices.isEmpty {
            for i in collectedIndices.reversed() {
                state.shoots.remove(at: i)
            }
            let multiplier = state.kinShootMultiplier * state.tuning.shootScoreMultiplier
            state.shootsCollected += collectedIndices.count
            state.score += GameConstants.shootScoreBonus * multiplier * collectedIndices.count
            state.powerCharge = min(100, state.powerCharge + GameConstants.shootChargePerPickup * CGFloat(collectedIndices.count))
            WKInterfaceDevice.current().play(.click)
        }

        state.shoots.removeAll { $0.x < -20 }
    }

    private static func updatePowerUp(state: GameState, dt: TimeInterval) {
        guard state.powerUpActive else { return }
        state.powerUpTimeRemaining -= dt
        if state.powerUpTimeRemaining <= 0 {
            state.powerUpActive = false
            state.powerUpTimeRemaining = 0
        }
    }

    private static func updateSeasonBanner(state: GameState) {
        let currentIndex = state.season.rawValue
        if currentIndex != state.lastSeasonIndex {
            state.lastSeasonIndex = currentIndex
            state.seasonBannerVisibleUntil = Date().addingTimeInterval(GameConstants.seasonBannerDuration)
        }
    }

    // MARK: - Spawning

    /// Distance-based spawn gaps get covered faster as `gameSpeed` ramps up, which otherwise
    /// squeezes the *time* between obstacles down toward zero the longer a run goes. Scaling
    /// gaps by how far above the initial speed we are keeps the pace from spiraling into an
    /// unplayable wall while still letting things feel busier at high speed.
    private static func speedGapScale(state: GameState) -> CGFloat {
        state.gameSpeed / GameConstants.initialSpeed
    }

    private static func jitteredGap(_ base: CGFloat, state: GameState) -> CGFloat {
        base * speedGapScale(state: state) * CGFloat.random(in: GameConstants.obstacleGapSpeedJitter)
    }

    private static func spawnObstaclesIfNeeded(state: GameState, canvasSize: CGSize, tuning: WorldSeasonTuning) {
        let spawnX = canvasSize.width + 20
        let gapSinceLastSpawn = state.distanceTraveled - state.lastObstacleSpawnDistance

        switch state.world.mechanic {
        case .rhythm:
            let requiredGap = jitteredGap(GameConstants.rhythmGap, state: state)
            guard gapSinceLastSpawn >= requiredGap else { return }
            let type = GameState.rhythmPattern[state.rhythmPatternIndex % GameState.rhythmPattern.count]
            state.rhythmPatternIndex += 1
            state.obstacles.append(.rhythm(atX: spawnX, type: type, heightMultiplier: tuning.obstacleHeightMultiplier))
            state.lastObstacleSpawnDistance = state.distanceTraveled

        case .elevation:
            break // Mist Terraces has nothing to dodge — the gaps between platforms are the hazard.

        case .overhead:
            // Snow Pass: an icicle drops in from the top of the screen, in the panda's path —
            // it isn't solid (and can't hit or be jumped) until it finishes falling and lands.
            let requiredGap = jitteredGap(CGFloat.random(in: GameConstants.minObstacleGap * 1.4...GameConstants.maxObstacleGap * 1.4), state: state)
            guard gapSinceLastSpawn >= requiredGap else { return }
            state.obstacles.append(.fallingIcicle(atX: spawnX, heightMultiplier: tuning.obstacleHeightMultiplier * 0.7))
            state.lastObstacleSpawnDistance = state.distanceTraveled

        case .tempo:
            let requiredGap = jitteredGap(GameConstants.tempoGap, state: state) / tuning.hazardDensityMultiplier
            guard gapSinceLastSpawn >= requiredGap else { return }
            state.obstacles.append(.random(atX: spawnX, heightMultiplier: tuning.obstacleHeightMultiplier))
            state.lastObstacleSpawnDistance = state.distanceTraveled

        case .unstable:
            let requiredGap = jitteredGap(CGFloat.random(in: GameConstants.minObstacleGap...GameConstants.maxObstacleGap), state: state)
            guard gapSinceLastSpawn >= requiredGap else { return }
            state.obstacles.append(.random(atX: spawnX, heightMultiplier: tuning.obstacleHeightMultiplier))
            state.lastObstacleSpawnDistance = state.distanceTraveled
        }
    }

    private static func spawnOverheadIfNeeded(state: GameState, canvasSize: CGSize, tuning: WorldSeasonTuning) {
        // Snow Pass no longer has duck-hazards — its icicles fall into the panda's path as
        // ground obstacles instead (see spawnObstaclesIfNeeded's .overhead case).
        guard state.world.mechanic == .tempo else { return }

        let spawnX = canvasSize.width + 20
        let gapSinceLastSpawn = state.distanceTraveled - state.lastOverheadSpawnDistance
        let requiredGap = jitteredGap(GameConstants.tempoGap * 1.4, state: state) / tuning.hazardDensityMultiplier

        guard gapSinceLastSpawn >= requiredGap else { return }

        state.overheadHazards.append(.randomLantern(atX: spawnX))
        state.lastOverheadSpawnDistance = state.distanceTraveled
    }

    private static func spawnTerracesIfNeeded(state: GameState, canvasSize: CGSize, tuning: WorldSeasonTuning) {
        guard state.world.mechanic == .elevation else { return }

        if state.terraces.isEmpty {
            // A wide starting slab so the player has solid footing before the first jump.
            state.terraces.append(Terrace(x: 0, width: canvasSize.width * 0.6, heightOffset: 0))
        }

        // Always keep at least two platforms queued past the right edge of the screen so a
        // gap is never encountered before its far-side platform has actually spawned.
        let lookahead = canvasSize.width + 80
        while (state.terraces.map { $0.x + $0.width }.max() ?? 0) < lookahead {
            let rightEdge = state.terraces.map { $0.x + $0.width }.max() ?? canvasSize.width
            let gapWidth = CGFloat.random(in: GameConstants.terraceGapWidth)
            let height = CGFloat.random(in: -18...18) * tuning.terraceHeightMultiplier
            state.terraces.append(Terrace(x: rightEdge + gapWidth, width: GameConstants.terraceSegmentLength, heightOffset: height))
        }
    }

    /// Ambient icicles falling behind the panda's fixed screen position — pure atmosphere for
    /// Snow Pass. They only ever spawn to the left of the panda (already-passed ground), so they
    /// can never be mistaken for something to react to.
    private static func spawnSkyIciclesIfNeeded(state: GameState, canvasSize: CGSize) {
        guard state.world.mechanic == .overhead else { return }

        let gapSinceLastSpawn = state.distanceTraveled - state.lastSkyIcicleSpawnDistance
        guard gapSinceLastSpawn >= GameConstants.skyIcicleGap else { return }

        state.skyIcicles.append(.random(behindX: state.dinosaur.x - 10))
        state.lastSkyIcicleSpawnDistance = state.distanceTraveled
    }

    private static func spawnShootsIfNeeded(state: GameState, canvasSize: CGSize) {
        let spawnX = canvasSize.width + 20
        let gapSinceLastSpawn = state.distanceTraveled - state.lastShootSpawnDistance
        let requiredGap = CGFloat.random(in: GameConstants.minShootGap...GameConstants.maxShootGap)

        guard gapSinceLastSpawn >= requiredGap else { return }

        state.shoots.append(Shoot.random(atX: spawnX))
        state.lastShootSpawnDistance = state.distanceTraveled
    }

    // MARK: - Collision

    private static func checkObstacleCollision(state: GameState, canvasSize: CGSize) -> Bool {
        let groundY = canvasSize.height - GameConstants.groundOffset - state.currentTerraceHeight

        let dinoRect = CGRect(
            x: state.dinosaur.x,
            y: groundY - state.dinosaur.y - state.dinosaur.currentHeight,
            width: state.dinosaur.width,
            height: state.dinosaur.currentHeight
        ).insetBy(dx: 4, dy: 4)

        for obstacle in state.obstacles {
            guard obstacle.fallProgress >= 1 else { continue }
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

    private static func checkOverheadCollision(state: GameState, canvasSize: CGSize) -> Bool {
        let groundY = canvasSize.height - GameConstants.groundOffset - state.currentTerraceHeight
        // Uses currentHeight (not the fixed standing height) so how far the panda actually
        // shrunk determines what it clears — a shallow duck only ducks a shallow lantern, an
        // extra-large one needs the panda genuinely small.
        let dinoTopY = groundY - state.dinosaur.y - state.dinosaur.currentHeight

        let dinoHeadRect = CGRect(x: state.dinosaur.x, y: dinoTopY, width: state.dinosaur.width, height: 3).insetBy(dx: 4, dy: 0)

        for hazard in state.overheadHazards {
            let hazardRect = CGRect(x: hazard.x, y: 0, width: hazard.width, height: hazard.reach)
            if hazardRect.intersects(dinoHeadRect) {
                return true
            }
        }

        return false
    }
}
