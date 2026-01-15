import SwiftUI
import WatchKit
import Combine

// Floating reward animation
struct FloatingReward: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let startTime: Date
    let startX: CGFloat
    let startY: CGFloat

    // Animation duration in seconds
    static let duration: TimeInterval = 1.0

    func opacity(at time: Date) -> Double {
        let elapsed = time.timeIntervalSince(startTime)
        let progress = elapsed / Self.duration
        if progress >= 1.0 { return 0 }
        // Fade out in last 40%
        if progress > 0.6 {
            return 1.0 - ((progress - 0.6) / 0.4)
        }
        return 1.0
    }

    func yOffset(at time: Date) -> CGFloat {
        let elapsed = time.timeIntervalSince(startTime)
        let progress = min(1.0, elapsed / Self.duration)
        // Float up 30 points
        return CGFloat(progress) * -30
    }

    func isExpired(at time: Date) -> Bool {
        time.timeIntervalSince(startTime) >= Self.duration
    }
}

// Reference type to avoid state modification warnings in render loop
private class GameTiming {
    var lastUpdateTime: Date?
}

struct GameView: View {
    var gameState: GameState
    let dinosaurSkin: DinosaurSkin
    let obstacleSkin: ObstacleSkin
    let backgroundSkin: BackgroundSkin

    @GestureState private var isTouching = false

    // Timing - use reference type to avoid state modification in render loop
    private let timing = GameTiming()

    // Animation state
    @State private var floatingRewards: [FloatingReward] = []
    @State private var lastCoinMilestone: Int = 0
    @State private var lastScoreMilestone: Int = 0
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let now = timeline.date
                Canvas { context, size in
                    // Update game physics using reference type (no state modification warning)
                    if let lastTime = timing.lastUpdateTime {
                        let deltaTime = now.timeIntervalSince(lastTime)
                        if deltaTime > 0 && deltaTime < 0.1 {
                            GameEngine.update(state: gameState, deltaTime: deltaTime, canvasSize: size)
                        }
                    }
                    timing.lastUpdateTime = now

                    render(context: context, size: size, currentTime: now)
                }
            }
            .onAppear {
                canvasSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                canvasSize = newSize
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isTouching) { _, state, _ in
                    if !state {
                        state = true
                        jump()
                    }
                }
        )
        .onChange(of: gameState.phase) { _, newPhase in
            if newPhase == .playing {
                // Reset milestones when game starts
                lastCoinMilestone = 0
                lastScoreMilestone = 0
                floatingRewards.removeAll()
                timing.lastUpdateTime = nil
            }
        }
        .onChange(of: gameState.score) { _, newScore in
            guard gameState.phase == .playing else { return }
            checkForRewards(newScore: newScore)
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Periodically clean up expired animations
            let now = Date()
            floatingRewards.removeAll { $0.isExpired(at: now) }
        }
    }

    private func checkForRewards(newScore: Int) {
        guard canvasSize != .zero else { return }

        let now = Date()

        // Position below the score (score is at x:30, y:20)
        let rewardX: CGFloat = 30
        let rewardY: CGFloat = 38

        // Check for coin milestones (every 10 points = 1 coin)
        let currentCoinLevel = newScore / 10
        if currentCoinLevel > lastCoinMilestone && currentCoinLevel > 0 {
            // Spawn coin animation
            let coinsEarned = currentCoinLevel - lastCoinMilestone
            spawnReward(
                text: "+\(coinsEarned)",
                color: .yellow,
                at: now,
                x: rewardX,
                y: rewardY
            )
            lastCoinMilestone = currentCoinLevel
        }

        // Check for score milestones (100, 200, 500, 1000)
        let milestones = [100, 200, 500, 1000]
        for milestone in milestones {
            if newScore >= milestone && lastScoreMilestone < milestone {
                // Spawn bonus animation
                let bonusText: String
                switch milestone {
                case 100: bonusText = "+5"
                case 200: bonusText = "+15"
                case 500: bonusText = "+30"
                case 1000: bonusText = "+50"
                default: bonusText = "+"
                }
                spawnReward(
                    text: bonusText,
                    color: .cyan,
                    at: now,
                    x: rewardX + 25,
                    y: rewardY
                )
                lastScoreMilestone = milestone

                // Haptic feedback for milestone
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    private func spawnReward(text: String, color: Color, at time: Date, x: CGFloat, y: CGFloat) {
        let reward = FloatingReward(
            text: text,
            color: color,
            startTime: time,
            startX: x,
            startY: y
        )
        floatingRewards.append(reward)
    }

    private func jump() {
        guard !gameState.dinosaur.isJumping else { return }
        WKInterfaceDevice.current().play(.click)
        GameEngine.jump(state: gameState)
    }

    private func render(context: GraphicsContext, size: CGSize, currentTime: Date) {
        let groundY = size.height - GameConstants.groundOffset

        // Background
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(backgroundSkin.backgroundColor)
        )

        // Background decorations
        renderBackgroundDecorations(context: context, size: size, groundY: groundY)

        // Ground line
        var groundPath = Path()
        groundPath.move(to: CGPoint(x: 0, y: groundY))
        groundPath.addLine(to: CGPoint(x: size.width, y: groundY))
        context.stroke(groundPath, with: .color(backgroundSkin.groundColor), lineWidth: 2)

        // Ground texture
        renderGroundTexture(context: context, size: size, groundY: groundY)

        // Dinosaur
        renderDinosaur(context: context, groundY: groundY)

        // Obstacles
        renderObstacles(context: context, groundY: groundY)

        // Score
        context.draw(
            Text("\(gameState.score)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white),
            at: CGPoint(x: 30, y: 20)
        )

        // Floating reward animations
        renderFloatingRewards(context: context, currentTime: currentTime)
    }

    private func renderFloatingRewards(context: GraphicsContext, currentTime: Date) {
        for reward in floatingRewards {
            let opacity = reward.opacity(at: currentTime)
            guard opacity > 0 else { continue }

            let yOffset = reward.yOffset(at: currentTime)

            context.draw(
                Text(reward.text)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(reward.color.opacity(opacity)),
                at: CGPoint(x: reward.startX, y: reward.startY + yOffset)
            )
        }
    }

    private func renderBackgroundDecorations(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        switch backgroundSkin {
        case .desertNight:
            break

        case .neonCity:
            // Building silhouettes
            let buildingOffset = gameState.groundOffset * 0.5
            for i in stride(from: -buildingOffset, to: size.width + 40, by: 40) {
                let height = CGFloat(20 + Int(i.rounded()) % 30)
                var building = Path()
                building.addRect(CGRect(x: i, y: groundY - height - 10, width: 8, height: height))
                context.fill(building, with: .color(.cyan.opacity(0.15)))
            }

        case .volcano:
            // Rising ember particles
            let emberPhase = gameState.distanceTraveled.truncatingRemainder(dividingBy: 100)
            for i in 0..<3 {
                let x = CGFloat(30 + i * 60) + emberPhase * 0.3
                let y = groundY - 20 - CGFloat(i * 15) - emberPhase * 0.5
                if y > 10 {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)),
                        with: .color(.orange.opacity(0.6))
                    )
                }
            }
        }
    }

    private func renderGroundTexture(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        let dashOffset = gameState.groundOffset
        let dashColor: Color

        switch backgroundSkin {
        case .desertNight:
            dashColor = .gray.opacity(0.5)
        case .neonCity:
            dashColor = .cyan.opacity(0.3)
        case .volcano:
            dashColor = .orange.opacity(0.4)
        }

        for i in stride(from: -dashOffset, to: size.width + 20, by: 20) {
            var dash = Path()
            dash.move(to: CGPoint(x: i, y: groundY + 5))
            dash.addLine(to: CGPoint(x: i + 10, y: groundY + 5))
            context.stroke(dash, with: .color(dashColor), lineWidth: 1)
        }
    }

    private func renderDinosaur(context: GraphicsContext, groundY: CGFloat) {
        let dinoScreenY = groundY - gameState.dinosaur.y - gameState.dinosaur.height
        let dinoRect = CGRect(
            x: gameState.dinosaur.x,
            y: dinoScreenY,
            width: gameState.dinosaur.width,
            height: gameState.dinosaur.height
        )

        // Main body
        context.fill(
            Path(roundedRect: dinoRect, cornerRadius: 4),
            with: .color(dinosaurSkin.primaryColor)
        )

        // Eye
        let eyeRect = CGRect(
            x: gameState.dinosaur.x + 16,
            y: dinoScreenY + 4,
            width: 4,
            height: 4
        )
        context.fill(Path(ellipseIn: eyeRect), with: .color(dinosaurSkin.eyeColor))

        // Skin-specific decorations
        switch dinosaurSkin {
        case .squaresaurus:
            break

        case .spike:
            // 3 triangle spikes on back
            for i in 0..<3 {
                var spike = Path()
                let baseX = gameState.dinosaur.x + 4 + CGFloat(i * 7)
                spike.move(to: CGPoint(x: baseX, y: dinoScreenY))
                spike.addLine(to: CGPoint(x: baseX + 3, y: dinoScreenY - 6))
                spike.addLine(to: CGPoint(x: baseX + 6, y: dinoScreenY))
                spike.closeSubpath()
                context.fill(spike, with: .color(.cyan))
            }

        case .chrome:
            // Metallic stripe
            let stripeRect = CGRect(
                x: gameState.dinosaur.x + 2,
                y: dinoScreenY + gameState.dinosaur.height * 0.3,
                width: gameState.dinosaur.width - 4,
                height: 4
            )
            context.fill(Path(stripeRect), with: .color(.white.opacity(0.4)))

        case .mechRex:
            // Antenna
            var antenna = Path()
            antenna.move(to: CGPoint(x: gameState.dinosaur.x + 12, y: dinoScreenY))
            antenna.addLine(to: CGPoint(x: gameState.dinosaur.x + 12, y: dinoScreenY - 8))
            context.stroke(antenna, with: .color(.gray), lineWidth: 2)

            // Antenna tip
            context.fill(
                Path(ellipseIn: CGRect(x: gameState.dinosaur.x + 10, y: dinoScreenY - 10, width: 4, height: 4)),
                with: .color(.cyan)
            )

            // Gear pattern
            context.stroke(
                Path(ellipseIn: CGRect(x: gameState.dinosaur.x + 6, y: dinoScreenY + 10, width: 8, height: 8)),
                with: .color(.gray),
                lineWidth: 1
            )

        case .dragon:
            // Wing on left side
            var leftWing = Path()
            leftWing.move(to: CGPoint(x: gameState.dinosaur.x, y: dinoScreenY + 8))
            leftWing.addLine(to: CGPoint(x: gameState.dinosaur.x - 8, y: dinoScreenY + 4))
            leftWing.addLine(to: CGPoint(x: gameState.dinosaur.x - 6, y: dinoScreenY + 12))
            leftWing.addLine(to: CGPoint(x: gameState.dinosaur.x, y: dinoScreenY + 14))
            leftWing.closeSubpath()
            context.fill(leftWing, with: .color(.purple.opacity(0.7)))

            // Flame trail when moving
            if gameState.phase == .playing {
                var flame = Path()
                flame.move(to: CGPoint(x: gameState.dinosaur.x - 2, y: dinoScreenY + gameState.dinosaur.height - 4))
                flame.addLine(to: CGPoint(x: gameState.dinosaur.x - 10, y: dinoScreenY + gameState.dinosaur.height))
                flame.addLine(to: CGPoint(x: gameState.dinosaur.x - 2, y: dinoScreenY + gameState.dinosaur.height + 4))
                flame.closeSubpath()
                context.fill(flame, with: .color(.orange))
            }
        }
    }

    private func renderObstacles(context: GraphicsContext, groundY: CGFloat) {
        for obstacle in gameState.obstacles {
            let obstacleRect = CGRect(
                x: obstacle.x,
                y: groundY - obstacle.height,
                width: obstacle.width,
                height: obstacle.height
            )

            switch obstacleSkin {
            case .cactus:
                context.fill(
                    Path(roundedRect: obstacleRect, cornerRadius: 2),
                    with: .color(.red)
                )

            case .crystal:
                // Diamond-ish shape
                var crystalPath = Path()
                crystalPath.move(to: CGPoint(x: obstacle.x, y: groundY))
                crystalPath.addLine(to: CGPoint(x: obstacle.x, y: groundY - obstacle.height + 6))
                crystalPath.addLine(to: CGPoint(x: obstacle.x + obstacle.width / 2, y: groundY - obstacle.height))
                crystalPath.addLine(to: CGPoint(x: obstacle.x + obstacle.width, y: groundY - obstacle.height + 6))
                crystalPath.addLine(to: CGPoint(x: obstacle.x + obstacle.width, y: groundY))
                crystalPath.closeSubpath()
                context.fill(crystalPath, with: .color(.cyan))

                // Inner highlight
                context.fill(
                    Path(CGRect(x: obstacle.x + 2, y: groundY - obstacle.height + 8, width: 3, height: obstacle.height - 12)),
                    with: .color(.white.opacity(0.3))
                )

            case .lavaRock:
                context.fill(
                    Path(roundedRect: obstacleRect, cornerRadius: 2),
                    with: .color(obstacleSkin.primaryColor)
                )

                // Hot glow at top
                let glowRect = CGRect(
                    x: obstacle.x + 2,
                    y: groundY - obstacle.height + 2,
                    width: obstacle.width - 4,
                    height: 4
                )
                context.fill(Path(glowRect), with: .color(.orange))
            }
        }
    }
}
