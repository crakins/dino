import SwiftUI
import UIKit

// Reference type to avoid state modification warnings in render loop
private class GameTiming {
    var lastUpdateTime: Date?
}

struct iPhoneGameView: View {
    var gameState: GameState
    let dinosaurSkin: DinosaurSkin
    let obstacleSkin: ObstacleSkin
    let backgroundSkin: BackgroundSkin

    // Timing - use reference type to avoid state modification in render loop
    private let timing = GameTiming()

    // Haptic feedback
    private let jumpFeedback = UIImpactFeedbackGenerator(style: .light)
    private let collisionFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let now = timeline.date
                Canvas { context, size in
                    // Update game physics
                    if let lastTime = timing.lastUpdateTime {
                        let deltaTime = now.timeIntervalSince(lastTime)
                        if deltaTime > 0 && deltaTime < 0.1 {
                            let collision = GameEngine.update(state: gameState, deltaTime: deltaTime, canvasSize: size)
                            if collision {
                                // Trigger haptic on collision (will be called once)
                                DispatchQueue.main.async {
                                    collisionFeedback.notificationOccurred(.error)
                                }
                            }
                        }
                    }
                    timing.lastUpdateTime = now

                    render(context: context, size: size)
                }
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            jump()
        }
        .onChange(of: gameState.phase) { _, newPhase in
            if newPhase == .playing {
                timing.lastUpdateTime = nil
            }
        }
        .onAppear {
            jumpFeedback.prepare()
            collisionFeedback.prepare()
        }
    }

    private func jump() {
        guard !gameState.dinosaur.isJumping && gameState.phase == .playing else { return }
        jumpFeedback.impactOccurred()
        GameEngine.jump(state: gameState)
    }

    private func render(context: GraphicsContext, size: CGSize) {
        let groundY = size.height - GameConstants.groundOffset * 3 // Scale ground offset for larger screen

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
        context.stroke(groundPath, with: .color(backgroundSkin.groundColor), lineWidth: 3)

        // Ground texture
        renderGroundTexture(context: context, size: size, groundY: groundY)

        // Dinosaur
        renderDinosaur(context: context, size: size, groundY: groundY)

        // Obstacles
        renderObstacles(context: context, size: size, groundY: groundY)

        // Score - top left
        context.draw(
            Text("\(gameState.score)")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white),
            at: CGPoint(x: 60, y: 60)
        )
    }

    private func renderBackgroundDecorations(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        switch backgroundSkin {
        case .desertNight:
            // Stars
            for i in 0..<10 {
                let x = CGFloat(50 + i * 40)
                let y = CGFloat(80 + (i % 3) * 50)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)),
                    with: .color(.white.opacity(0.5))
                )
            }

        case .neonCity:
            let buildingOffset = gameState.groundOffset * 0.5
            for i in stride(from: -buildingOffset, to: size.width + 80, by: 80) {
                let height = CGFloat(60 + Int(i.rounded()) % 80)
                var building = Path()
                building.addRect(CGRect(x: i, y: groundY - height - 20, width: 20, height: height))
                context.fill(building, with: .color(.cyan.opacity(0.15)))
            }

        case .volcano:
            let emberPhase = gameState.distanceTraveled.truncatingRemainder(dividingBy: 200)
            for i in 0..<6 {
                let x = CGFloat(60 + i * 80) + emberPhase * 0.3
                let y = groundY - 40 - CGFloat(i * 30) - emberPhase * 0.5
                if y > 20 {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 6, height: 6)),
                        with: .color(.orange.opacity(0.6))
                    )
                }
            }
        }
    }

    private func renderGroundTexture(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        let dashOffset = gameState.groundOffset * 2
        let dashColor: Color

        switch backgroundSkin {
        case .desertNight:
            dashColor = .gray.opacity(0.5)
        case .neonCity:
            dashColor = .cyan.opacity(0.3)
        case .volcano:
            dashColor = .orange.opacity(0.4)
        }

        for i in stride(from: -dashOffset, to: size.width + 40, by: 40) {
            var dash = Path()
            dash.move(to: CGPoint(x: i, y: groundY + 10))
            dash.addLine(to: CGPoint(x: i + 20, y: groundY + 10))
            context.stroke(dash, with: .color(dashColor), lineWidth: 2)
        }
    }

    private func renderDinosaur(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        // Scale dinosaur for iPhone (roughly 2x watch size)
        let scale: CGFloat = 2.5
        let dinoWidth = gameState.dinosaur.width * scale
        let dinoHeight = gameState.dinosaur.height * scale
        let dinoX = gameState.dinosaur.x * scale
        let dinoY = gameState.dinosaur.y * scale

        let dinoScreenY = groundY - dinoY - dinoHeight
        let dinoRect = CGRect(
            x: dinoX,
            y: dinoScreenY,
            width: dinoWidth,
            height: dinoHeight
        )

        // Main body
        context.fill(
            Path(roundedRect: dinoRect, cornerRadius: 8),
            with: .color(dinosaurSkin.primaryColor)
        )

        // Eye
        let eyeRect = CGRect(
            x: dinoX + dinoWidth * 0.65,
            y: dinoScreenY + dinoHeight * 0.15,
            width: 10,
            height: 10
        )
        context.fill(Path(ellipseIn: eyeRect), with: .color(dinosaurSkin.eyeColor))

        // Skin-specific decorations
        switch dinosaurSkin {
        case .squaresaurus:
            break

        case .spike:
            for i in 0..<3 {
                var spike = Path()
                let baseX = dinoX + 10 + CGFloat(i * 18)
                spike.move(to: CGPoint(x: baseX, y: dinoScreenY))
                spike.addLine(to: CGPoint(x: baseX + 7, y: dinoScreenY - 15))
                spike.addLine(to: CGPoint(x: baseX + 14, y: dinoScreenY))
                spike.closeSubpath()
                context.fill(spike, with: .color(.cyan))
            }

        case .chrome:
            let stripeRect = CGRect(
                x: dinoX + 5,
                y: dinoScreenY + dinoHeight * 0.3,
                width: dinoWidth - 10,
                height: 8
            )
            context.fill(Path(stripeRect), with: .color(.white.opacity(0.4)))

        case .mechRex:
            var antenna = Path()
            antenna.move(to: CGPoint(x: dinoX + dinoWidth * 0.5, y: dinoScreenY))
            antenna.addLine(to: CGPoint(x: dinoX + dinoWidth * 0.5, y: dinoScreenY - 20))
            context.stroke(antenna, with: .color(.gray), lineWidth: 4)

            context.fill(
                Path(ellipseIn: CGRect(x: dinoX + dinoWidth * 0.5 - 5, y: dinoScreenY - 25, width: 10, height: 10)),
                with: .color(.cyan)
            )

            context.stroke(
                Path(ellipseIn: CGRect(x: dinoX + 15, y: dinoScreenY + dinoHeight * 0.4, width: 20, height: 20)),
                with: .color(.gray),
                lineWidth: 2
            )

        case .dragon:
            var leftWing = Path()
            leftWing.move(to: CGPoint(x: dinoX, y: dinoScreenY + dinoHeight * 0.3))
            leftWing.addLine(to: CGPoint(x: dinoX - 20, y: dinoScreenY + dinoHeight * 0.15))
            leftWing.addLine(to: CGPoint(x: dinoX - 15, y: dinoScreenY + dinoHeight * 0.5))
            leftWing.addLine(to: CGPoint(x: dinoX, y: dinoScreenY + dinoHeight * 0.55))
            leftWing.closeSubpath()
            context.fill(leftWing, with: .color(.purple.opacity(0.7)))

            if gameState.phase == .playing {
                var flame = Path()
                flame.move(to: CGPoint(x: dinoX - 5, y: dinoScreenY + dinoHeight - 10))
                flame.addLine(to: CGPoint(x: dinoX - 25, y: dinoScreenY + dinoHeight))
                flame.addLine(to: CGPoint(x: dinoX - 5, y: dinoScreenY + dinoHeight + 10))
                flame.closeSubpath()
                context.fill(flame, with: .color(.orange))
            }
        }
    }

    private func renderObstacles(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        let scale: CGFloat = 2.5

        for obstacle in gameState.obstacles {
            let obstacleX = obstacle.x * scale
            let obstacleWidth = obstacle.width * scale
            let obstacleHeight = obstacle.height * scale

            let obstacleRect = CGRect(
                x: obstacleX,
                y: groundY - obstacleHeight,
                width: obstacleWidth,
                height: obstacleHeight
            )

            switch obstacleSkin {
            case .cactus:
                context.fill(
                    Path(roundedRect: obstacleRect, cornerRadius: 4),
                    with: .color(.red)
                )

            case .crystal:
                var crystalPath = Path()
                crystalPath.move(to: CGPoint(x: obstacleX, y: groundY))
                crystalPath.addLine(to: CGPoint(x: obstacleX, y: groundY - obstacleHeight + 15))
                crystalPath.addLine(to: CGPoint(x: obstacleX + obstacleWidth / 2, y: groundY - obstacleHeight))
                crystalPath.addLine(to: CGPoint(x: obstacleX + obstacleWidth, y: groundY - obstacleHeight + 15))
                crystalPath.addLine(to: CGPoint(x: obstacleX + obstacleWidth, y: groundY))
                crystalPath.closeSubpath()
                context.fill(crystalPath, with: .color(.cyan))

                context.fill(
                    Path(CGRect(x: obstacleX + 5, y: groundY - obstacleHeight + 20, width: 6, height: obstacleHeight - 30)),
                    with: .color(.white.opacity(0.3))
                )

            case .lavaRock:
                context.fill(
                    Path(roundedRect: obstacleRect, cornerRadius: 4),
                    with: .color(obstacleSkin.primaryColor)
                )

                let glowRect = CGRect(
                    x: obstacleX + 5,
                    y: groundY - obstacleHeight + 5,
                    width: obstacleWidth - 10,
                    height: 10
                )
                context.fill(Path(glowRect), with: .color(.orange))
            }
        }
    }
}
