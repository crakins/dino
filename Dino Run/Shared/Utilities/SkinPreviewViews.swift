import SwiftUI

// MARK: - Dinosaur Preview

struct DinosaurPreview: View {
    let skin: DinosaurSkin
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 28 // Base size is 28
            let width = 24 * scale
            let height = 24 * scale
            let x = (canvasSize.width - width) / 2
            let y = (canvasSize.height - height) / 2

            // Main body
            let bodyRect = CGRect(x: x, y: y, width: width, height: height)
            context.fill(
                Path(roundedRect: bodyRect, cornerRadius: 3 * scale),
                with: .color(skin.primaryColor)
            )

            // Eye
            let eyeRect = CGRect(
                x: x + 14 * scale,
                y: y + 4 * scale,
                width: 4 * scale,
                height: 4 * scale
            )
            context.fill(Path(ellipseIn: eyeRect), with: .color(skin.eyeColor))

            // Skin-specific decorations
            switch skin {
            case .squaresaurus:
                break

            case .spike:
                // 3 triangle spikes on back
                for i in 0..<3 {
                    var spike = Path()
                    let baseX = x + (3 + CGFloat(i) * 6) * scale
                    spike.move(to: CGPoint(x: baseX, y: y))
                    spike.addLine(to: CGPoint(x: baseX + 2.5 * scale, y: y - 5 * scale))
                    spike.addLine(to: CGPoint(x: baseX + 5 * scale, y: y))
                    spike.closeSubpath()
                    context.fill(spike, with: .color(.cyan))
                }

            case .chrome:
                // Metallic stripe
                let stripeRect = CGRect(
                    x: x + 2 * scale,
                    y: y + height * 0.3,
                    width: width - 4 * scale,
                    height: 3 * scale
                )
                context.fill(Path(stripeRect), with: .color(.white.opacity(0.4)))

            case .mechRex:
                // Antenna
                var antenna = Path()
                antenna.move(to: CGPoint(x: x + 10 * scale, y: y))
                antenna.addLine(to: CGPoint(x: x + 10 * scale, y: y - 6 * scale))
                context.stroke(antenna, with: .color(.gray), lineWidth: 1.5 * scale)

                // Antenna tip
                context.fill(
                    Path(ellipseIn: CGRect(x: x + 8 * scale, y: y - 8 * scale, width: 4 * scale, height: 4 * scale)),
                    with: .color(.cyan)
                )

                // Gear pattern
                context.stroke(
                    Path(ellipseIn: CGRect(x: x + 5 * scale, y: y + 8 * scale, width: 6 * scale, height: 6 * scale)),
                    with: .color(.gray),
                    lineWidth: 1
                )

            case .dragon:
                // Wing
                var wing = Path()
                wing.move(to: CGPoint(x: x, y: y + 6 * scale))
                wing.addLine(to: CGPoint(x: x - 6 * scale, y: y + 3 * scale))
                wing.addLine(to: CGPoint(x: x - 4 * scale, y: y + 10 * scale))
                wing.addLine(to: CGPoint(x: x, y: y + 12 * scale))
                wing.closeSubpath()
                context.fill(wing, with: .color(.purple.opacity(0.7)))

                // Flame trail
                var flame = Path()
                flame.move(to: CGPoint(x: x - 1 * scale, y: y + height - 3 * scale))
                flame.addLine(to: CGPoint(x: x - 7 * scale, y: y + height))
                flame.addLine(to: CGPoint(x: x - 1 * scale, y: y + height + 3 * scale))
                flame.closeSubpath()
                context.fill(flame, with: .color(.orange))
            }
        }
        .frame(width: size + 16, height: size + 16)
    }
}

// MARK: - Obstacle Preview

struct ObstaclePreview: View {
    let skin: ObstacleSkin
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let width: CGFloat = 12
            let height: CGFloat = 24
            let scale = size / 28
            let x = (canvasSize.width - width * scale) / 2
            let y = (canvasSize.height - height * scale) / 2

            switch skin {
            case .cactus:
                // Simple rectangle
                let rect = CGRect(x: x, y: y, width: width * scale, height: height * scale)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 2 * scale),
                    with: .color(skin.primaryColor)
                )

            case .crystal:
                // Diamond shape
                var crystalPath = Path()
                let baseY = y + height * scale
                crystalPath.move(to: CGPoint(x: x, y: baseY))
                crystalPath.addLine(to: CGPoint(x: x, y: y + 5 * scale))
                crystalPath.addLine(to: CGPoint(x: x + (width / 2) * scale, y: y))
                crystalPath.addLine(to: CGPoint(x: x + width * scale, y: y + 5 * scale))
                crystalPath.addLine(to: CGPoint(x: x + width * scale, y: baseY))
                crystalPath.closeSubpath()
                context.fill(crystalPath, with: .color(.cyan))

                // Inner highlight
                context.fill(
                    Path(CGRect(x: x + 2 * scale, y: y + 7 * scale, width: 2 * scale, height: (height - 10) * scale)),
                    with: .color(.white.opacity(0.4))
                )

            case .lavaRock:
                // Rectangle with glow
                let rect = CGRect(x: x, y: y, width: width * scale, height: height * scale)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 2 * scale),
                    with: .color(skin.primaryColor)
                )

                // Hot glow at top
                let glowRect = CGRect(
                    x: x + 2 * scale,
                    y: y + 2 * scale,
                    width: (width - 4) * scale,
                    height: 3 * scale
                )
                context.fill(Path(glowRect), with: .color(.orange))
            }
        }
        .frame(width: size, height: size + 8)
    }
}

// MARK: - Background Preview

struct BackgroundPreview: View {
    let skin: BackgroundSkin
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            // Background
            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .color(skin.backgroundColor)
            )

            // Ground
            let groundY = canvasSize.height - 6
            context.fill(
                Path(CGRect(x: 0, y: groundY, width: canvasSize.width, height: 6)),
                with: .color(skin.groundColor)
            )

            // Decorations based on skin
            switch skin {
            case .desertNight:
                // Stars
                for i in 0..<3 {
                    let starX = 8 + CGFloat(i) * 12
                    let starY = 6 + CGFloat(i % 2) * 4
                    context.fill(
                        Path(ellipseIn: CGRect(x: starX, y: starY, width: 2, height: 2)),
                        with: .color(.white.opacity(0.5))
                    )
                }

            case .neonCity:
                // Building silhouettes
                for i in 0..<3 {
                    let buildingX = 4 + CGFloat(i) * 14
                    let buildingHeight: CGFloat = 8 + CGFloat(i % 2) * 4
                    context.fill(
                        Path(CGRect(x: buildingX, y: groundY - buildingHeight, width: 6, height: buildingHeight)),
                        with: .color(.cyan.opacity(0.3))
                    )
                }

            case .volcano:
                // Ember particles
                for i in 0..<3 {
                    let emberX = 10 + CGFloat(i) * 10
                    let emberY = 8 + CGFloat(i) * 3
                    context.fill(
                        Path(ellipseIn: CGRect(x: emberX, y: emberY, width: 3, height: 3)),
                        with: .color(.orange.opacity(0.7))
                    )
                }
            }
        }
        .frame(width: size * 1.5, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
