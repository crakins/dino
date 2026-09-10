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

    static let duration: TimeInterval = 1.0

    func opacity(at time: Date) -> Double {
        let elapsed = time.timeIntervalSince(startTime)
        let progress = elapsed / Self.duration
        if progress >= 1.0 { return 0 }
        if progress > 0.6 {
            return 1.0 - ((progress - 0.6) / 0.4)
        }
        return 1.0
    }

    func yOffset(at time: Date) -> CGFloat {
        let elapsed = time.timeIntervalSince(startTime)
        let progress = min(1.0, elapsed / Self.duration)
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
    var playerDataManager: PlayerDataManager

    @GestureState private var isTouching = false

    private let timing = GameTiming()

    @State private var floatingRewards: [FloatingReward] = []
    @State private var lastScoreMilestone: Int = 0
    @State private var lastShootsCollected: Int = 0
    @State private var canvasSize: CGSize = .zero
    @State private var crownValue: Double = 0
    @State private var lanternTipVisibleUntil: Date?

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let now = timeline.date
                Canvas { context, size in
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
                .updating($isTouching) { value, state, _ in
                    if !state {
                        state = true
                        handleTouchDown(at: value.startLocation)
                    }
                }
        )
        .focusable(true)
        .digitalCrownRotation($crownValue, from: -1, through: 0, by: 0.01, sensitivity: .high, isContinuous: true)
        .onChange(of: crownValue) { oldValue, newValue in
            // Rotating the crown "down" (negative) shrinks the panda live — 0 is full size, -1
            // is as small as it gets. No snap-back: it tracks the crown position directly, so
            // turning it back up grows the panda back out.
            let wasDucking = gameState.dinosaur.isDucking
            GameEngine.setDuckLevel(state: gameState, level: -newValue)
            if !wasDucking && gameState.dinosaur.isDucking {
                WKInterfaceDevice.current().play(.directionDown)
            }
        }
        .onChange(of: gameState.phase) { _, newPhase in
            if newPhase == .playing {
                lastScoreMilestone = 0
                lastShootsCollected = 0
                floatingRewards.removeAll()
                timing.lastUpdateTime = nil

                if gameState.world == .lanternRow && !playerDataManager.playerData.seenLanternRowTip {
                    lanternTipVisibleUntil = Date().addingTimeInterval(GameConstants.lanternTipDuration)
                    playerDataManager.markLanternRowTipSeen()
                }
            }
        }
        .onChange(of: gameState.score) { _, newScore in
            guard gameState.phase == .playing else { return }
            checkForScoreMilestone(newScore: newScore)
        }
        .onChange(of: gameState.shootsCollected) { _, newValue in
            guard gameState.phase == .playing, newValue > lastShootsCollected else { return }
            let gained = newValue - lastShootsCollected
            lastShootsCollected = newValue
            spawnReward(
                text: "+\(gained * GameConstants.shootScoreBonus)",
                color: PandaColor.greenMint,
                at: Date(),
                x: gameState.dinosaur.x + 12,
                y: 26
            )
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            let now = Date()
            floatingRewards.removeAll { $0.isExpired(at: now) }
        }
    }

    // MARK: - Input

    private func handleTouchDown(at location: CGPoint) {
        guard canvasSize != .zero else {
            jump()
            return
        }
        let holdHitRect = CGRect(x: canvasSize.width - 40, y: 0, width: 40, height: 80)
        if holdHitRect.contains(location) && gameState.powerCharge >= 100 {
            GameEngine.activatePowerUp(state: gameState)
        } else {
            jump()
        }
    }

    private func jump() {
        guard !gameState.dinosaur.isJumping else { return }
        WKInterfaceDevice.current().play(.click)
        GameEngine.jump(state: gameState)
    }

    // MARK: - Rewards

    private func checkForScoreMilestone(newScore: Int) {
        let milestones = [100, 200, 500, 1000]
        for milestone in milestones {
            if newScore >= milestone && lastScoreMilestone < milestone {
                let bonusText: String
                switch milestone {
                case 100: bonusText = "+5"
                case 200: bonusText = "+15"
                case 500: bonusText = "+30"
                case 1000: bonusText = "+50"
                default: bonusText = "+"
                }
                spawnReward(text: bonusText, color: PandaColor.greenMint, at: Date(), x: 46, y: 26)
                lastScoreMilestone = milestone
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    private func spawnReward(text: String, color: Color, at time: Date, x: CGFloat, y: CGFloat) {
        floatingRewards.append(FloatingReward(text: text, color: color, startTime: time, startX: x, startY: y))
    }

    // MARK: - Render

    private func render(context: GraphicsContext, size: CGSize, currentTime: Date) {
        let groundY = size.height - GameConstants.groundOffset - gameState.currentTerraceHeight
        // Fixed reference line for background elements — doesn't bob with terrace height changes.
        let baseGroundY = size.height - GameConstants.groundOffset
        let season = gameState.season
        let accent = season.accentColor

        switch gameState.world {
        case .bambooGrove:
            renderSeasonSky(context: context, size: size, season: season)
            renderBambooForest(context: context, size: size, groundY: baseGroundY, season: season)
            renderBambooWeather(context: context, size: size, season: season, currentTime: currentTime)
            renderSeasonBird(context: context, size: size, season: season, currentTime: currentTime)
        case .mistTerraces:
            renderSeasonSky(context: context, size: size, season: season)
            renderMistBackdrop(context: context, size: size, groundY: baseGroundY, season: season)
            renderMistWeather(context: context, size: size, season: season, currentTime: currentTime)
            renderSeasonBird(context: context, size: size, season: season, currentTime: currentTime)
        default:
            // Background
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: 0x1A1210), PandaColor.ink]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height * 0.62)
                )
            )

            renderMountains(context: context, size: size, groundY: groundY, accent: accent)
            renderAmbientDots(context: context, currentTime: currentTime)
        }

        if gameState.world.mechanic == .elevation {
            renderTerraces(context: context, size: size, groundY: groundY, season: season)
        } else {
            // Ground line
            context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 1)), with: .color(accent.opacity(0.5)))

            // Scrolling ground dashes
            var dashPath = Path()
            dashPath.move(to: CGPoint(x: -20 + (20 - gameState.groundOffset), y: groundY - 6))
            dashPath.addLine(to: CGPoint(x: size.width + 20, y: groundY - 6))
            context.stroke(dashPath, with: .color(accent.opacity(0.55)), style: StrokeStyle(lineWidth: 2, dash: [10, 10]))

            // Ground wash
            context.fill(
                Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
                with: .color(accent.opacity(0.05))
            )
        }
        renderShadow(context: context, groundY: groundY)
        renderGroundStability(context: context, size: size, groundY: groundY, currentTime: currentTime)
        renderSkyIcicles(context: context, groundY: groundY)
        renderObstacles(context: context, groundY: groundY, season: season)
        renderOverheadHazards(context: context, currentTime: currentTime)
        renderShoots(context: context, groundY: groundY)
        renderPanda(context: context, groundY: groundY)

        renderHUD(context: context, size: size, currentTime: currentTime)
        renderFloatingRewards(context: context, currentTime: currentTime)
    }

    private func renderMountains(context: GraphicsContext, size: CGSize, groundY: CGFloat, accent: Color) {
        let tileWidth: CGFloat = 116
        let baseY = groundY - 12
        let offset = (gameState.distanceTraveled * 0.15).truncatingRemainder(dividingBy: tileWidth)

        let peaks: [(w: CGFloat, h: CGFloat, opacity: Double)] = [(34, 16, 0.18), (44, 24, 0.14), (38, 14, 0.16)]

        var x = -offset - tileWidth
        while x < size.width + tileWidth {
            var cursor = x
            for peak in peaks {
                var path = Path()
                path.move(to: CGPoint(x: cursor, y: baseY))
                path.addLine(to: CGPoint(x: cursor + peak.w * 0.4, y: baseY - peak.h))
                path.addLine(to: CGPoint(x: cursor + peak.w, y: baseY))
                path.closeSubpath()
                context.fill(path, with: .color(accent.opacity(peak.opacity)))
                cursor += peak.w
            }
            x += tileWidth
        }
    }

    private func renderAmbientDots(context: GraphicsContext, currentTime: Date) {
        let pulse = (sin(currentTime.timeIntervalSinceReferenceDate * 1.4) + 1) / 2
        let dots: [(CGPoint, CGFloat, Double)] = [
            (CGPoint(x: 12, y: 34), 1.5, 0.5),
            (CGPoint(x: 52, y: 22), 1, 0.4),
            (CGPoint(x: 118, y: 44), 1, 0.35)
        ]
        for (point, radius, baseOpacity) in dots {
            let opacity = baseOpacity * (0.6 + 0.4 * pulse)
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                with: .color(PandaColor.greenMint.opacity(opacity))
            )
        }
    }

    // MARK: - Season sky & bird (shared by Bamboo Grove and Mist Terraces)

    private func seasonSkyColors(for season: Season) -> [Color] {
        switch season {
        case .spring: return [Color(hex: 0x2A4A5E), Color(hex: 0x2C4E63), Color(hex: 0x3E6478)]
        case .summer: return [Color(hex: 0x1E4A55), Color(hex: 0x20505C), Color(hex: 0x2E6672)]
        case .autumn: return [Color(hex: 0x33485C), Color(hex: 0x3A5266), Color(hex: 0x4C6478)]
        case .winter: return [Color(hex: 0x3D5C73), Color(hex: 0x456678), Color(hex: 0x5C808F)]
        }
    }

    private func renderSeasonSky(context: GraphicsContext, size: CGSize, season: Season) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: seasonSkyColors(for: season)),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        context.fill(
            Path(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.28)),
            with: .radialGradient(
                Gradient(colors: [PandaColor.greenMint.opacity(0.14), .clear]),
                center: CGPoint(x: size.width * 0.35, y: 0),
                startRadius: 0,
                endRadius: size.width * 0.7
            )
        )
    }

    private func renderSeasonBird(context: GraphicsContext, size: CGSize, season: Season, currentTime: Date) {
        let period: TimeInterval = { switch season {
        case .spring: return 7
        case .summer: return 6
        case .autumn: return 8
        case .winter: return 9
        } }()

        let t = currentTime.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        guard t < 0.4 else { return }

        let x = (t / 0.4) * (size.width + 20) - 10
        let y = size.height * 0.14
        let flap = sin(currentTime.timeIntervalSinceReferenceDate * 18) * 2

        var path = Path()
        path.move(to: CGPoint(x: x, y: y + flap))
        path.addLine(to: CGPoint(x: x + 6, y: y - 2))
        path.addLine(to: CGPoint(x: x + 7, y: y))
        path.addLine(to: CGPoint(x: x + 8, y: y - 2))
        path.addLine(to: CGPoint(x: x + 14, y: y + flap))
        context.stroke(path, with: .color(PandaColor.greenIce.opacity(0.7)), lineWidth: 1.2)
    }

    // MARK: - Bamboo Grove (forest backdrop + weather)

    private func renderBambooForest(context: GraphicsContext, size: CGSize, groundY: CGFloat, season: Season) {
        let stalkColors: (Color, Color) = {
            switch season {
            case .spring: return (Color(hex: 0x4E8C5C, opacity: 0.42), Color(hex: 0x6FBE7E, opacity: 0.6))
            case .summer: return (Color(hex: 0x4E8C5C, opacity: 0.55), PandaColor.greenPale.opacity(0.66))
            case .autumn: return (Color(hex: 0x96AFBE, opacity: 0.34), PandaColor.greenIce.opacity(0.44))
            case .winter: return (Color(hex: 0x96AFBE, opacity: 0.3), PandaColor.white.opacity(0.4))
            }
        }()

        let tileWidth: CGFloat = 9
        let scrollSpeed: CGFloat = season == .summer ? 0.22 : 0.15
        let offset = (gameState.distanceTraveled * scrollSpeed).truncatingRemainder(dividingBy: tileWidth * 2)
        let heights: [CGFloat] = [58, 74, 50, 88, 64, 96, 54, 80, 62, 102, 70, 52, 86, 66, 94, 58, 76, 62]

        var x = -offset - tileWidth * 2
        var i = 0
        while x < size.width + tileWidth {
            let h = heights[i % heights.count] * (groundY / 150)
            let color = i.isMultiple(of: 3) ? stalkColors.1 : stalkColors.0
            let rect = CGRect(x: x, y: groundY - h, width: 2, height: h)
            context.fill(Path(rect), with: .color(color))
            x += tileWidth
            i += 1
        }
    }

    private func renderBambooWeather(context: GraphicsContext, size: CGSize, season: Season, currentTime: Date) {
        let t = currentTime.timeIntervalSinceReferenceDate

        switch season {
        case .spring:
            let drops: [(CGFloat, TimeInterval, CGFloat)] = [(0.12, 1.5, 0), (0.31, 1.3, 0.4), (0.56, 1.7, 0.8), (0.78, 1.4, 1.1), (0.92, 1.6, 0.2)]
            for (xFrac, period, phase) in drops {
                let progress = ((t + phase).truncatingRemainder(dividingBy: period)) / period
                let y = progress * (size.height * 0.5)
                context.fill(Path(CGRect(x: size.width * xFrac, y: y, width: 1, height: 5)), with: .color(PandaColor.greenIce.opacity(0.45)))
            }
            let petals: [(CGFloat, TimeInterval, CGFloat)] = [(0.43, 4.4, 0), (0.71, 5.2, 1.6)]
            for (xFrac, period, phase) in petals {
                let progress = ((t + phase).truncatingRemainder(dividingBy: period)) / period
                let y = progress * size.height
                context.fill(Path(ellipseIn: CGRect(x: size.width * xFrac, y: y, width: 3, height: 3)), with: .color(PandaColor.white.opacity(0.6)))
            }

        case .summer:
            let fireflies: [(CGFloat, CGFloat, TimeInterval, TimeInterval)] = [
                (0.35, 0.34, 1.6, 0), (0.72, 0.46, 1.9, 0.4), (0.2, 0.58, 2.2, 0.9), (0.86, 0.4, 1.4, 1.3)
            ]
            for (xFrac, yFrac, period, phase) in fireflies {
                let pulse = (sin((t + phase) / period * 2 * .pi) + 1) / 2
                context.fill(
                    Path(ellipseIn: CGRect(x: size.width * xFrac, y: size.height * yFrac, width: 3, height: 3)),
                    with: .color(PandaColor.greenMint.opacity(0.35 + 0.45 * pulse))
                )
            }

        case .autumn:
            let leaves: [(CGFloat, TimeInterval, CGFloat)] = [(0.16, 3.2, 0), (0.4, 2.6, 0.5), (0.51, 3.8, 0.9), (0.71, 2.9, 1.4), (0.89, 3.4, 2.0)]
            for (xFrac, period, phase) in leaves {
                let progress = ((t + phase).truncatingRemainder(dividingBy: period)) / period
                let y = progress * size.height
                context.fill(
                    Path(ellipseIn: CGRect(x: size.width * xFrac, y: y, width: 4, height: 4)),
                    with: .color(PandaColor.greenMint.opacity(0.55))
                )
            }

        case .winter:
            let flakes: [(CGFloat, TimeInterval, CGFloat)] = [
                (0.1, 4.6, 0), (0.26, 5.4, 0.6), (0.44, 4.2, 1.2), (0.6, 5.8, 1.8), (0.76, 4.8, 2.4), (0.92, 5.2, 3.0)
            ]
            for (xFrac, period, phase) in flakes {
                let progress = ((t + phase).truncatingRemainder(dividingBy: period)) / period
                let y = progress * size.height
                context.fill(Path(ellipseIn: CGRect(x: size.width * xFrac, y: y, width: 2.5, height: 2.5)), with: .color(PandaColor.white.opacity(0.75)))
            }
        }
    }

    // MARK: - Mist Terraces (gorge backdrop + weather)

    private func renderMistBackdrop(context: GraphicsContext, size: CGSize, groundY: CGFloat, season: Season) {
        let (farColor, nearColor): (Color, Color) = {
            switch season {
            case .spring: return (Color(hex: 0x7894A4, opacity: 0.3), Color(hex: 0x92ACBA, opacity: 0.42))
            case .summer: return (Color(hex: 0x6E9696, opacity: 0.32), Color(hex: 0x8AB2B0, opacity: 0.44))
            case .autumn: return (Color(hex: 0x8C9EAA, opacity: 0.26), Color(hex: 0xA6B8C4, opacity: 0.34))
            case .winter: return (Color(hex: 0xA8BECC, opacity: 0.3), Color(hex: 0xC4D8E4, opacity: 0.4))
            }
        }()

        func ridgeLine(baseY: CGFloat, height: CGFloat, tileWidth: CGFloat, offset: CGFloat) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: -tileWidth, y: baseY))
            var x: CGFloat = -tileWidth - offset
            var toggle = false
            while x < size.width + tileWidth {
                let peakY = baseY - (toggle ? height : height * 0.55)
                path.addLine(to: CGPoint(x: x + tileWidth * 0.5, y: peakY))
                x += tileWidth * 0.5
                toggle.toggle()
            }
            path.addLine(to: CGPoint(x: size.width + tileWidth, y: baseY))
            path.addLine(to: CGPoint(x: size.width + tileWidth, y: size.height))
            path.addLine(to: CGPoint(x: -tileWidth, y: size.height))
            path.closeSubpath()
            return path
        }

        let farOffset = (gameState.distanceTraveled * 0.06).truncatingRemainder(dividingBy: 40)
        let nearOffset = (gameState.distanceTraveled * 0.11).truncatingRemainder(dividingBy: 28)

        context.fill(ridgeLine(baseY: groundY + 4, height: 58, tileWidth: 40, offset: farOffset), with: .color(farColor))
        context.fill(ridgeLine(baseY: groundY + 4, height: 40, tileWidth: 28, offset: nearOffset), with: .color(nearColor))
    }

    private func renderMistWeather(context: GraphicsContext, size: CGSize, season: Season, currentTime: Date) {
        let t = currentTime.timeIntervalSinceReferenceDate

        switch season {
        case .spring:
            // Meltwater trickles off the crags.
            let streams: [(CGFloat, CGFloat, TimeInterval, TimeInterval)] = [(0.3, 0.3, 1.4, 0), (0.68, 0.44, 1.6, 0.5)]
            for (xFrac, yFrac, period, phase) in streams {
                let progress = ((t + phase).truncatingRemainder(dividingBy: period)) / period
                let y = size.height * yFrac + progress * size.height * 0.22
                context.fill(Path(CGRect(x: size.width * xFrac, y: y, width: 1, height: 12)), with: .color(PandaColor.greenIce.opacity(0.4)))
            }

        case .summer:
            // Heat shimmer off the rock.
            let pulse = (sin(t * 1.8) + 1) / 2
            let bandY = size.height * 0.42
            context.fill(
                Path(CGRect(x: 0, y: bandY, width: size.width, height: 10)),
                with: .color(PandaColor.greenMint.opacity(0.06 + 0.05 * pulse))
            )

        case .autumn:
            // Fog banks drifting between the slabs.
            let drift = (sin(t * 0.5) + 1) / 2 * 10
            context.fill(
                Path(CGRect(x: -10 + drift, y: size.height * 0.5, width: size.width + 20, height: 22)),
                with: .color(PandaColor.white.opacity(0.05))
            )

        case .winter:
            let flakes: [(CGFloat, TimeInterval, CGFloat)] = [
                (0.14, 4.6, 0), (0.42, 5.4, 0.8), (0.68, 4.2, 1.6), (0.9, 5.8, 2.4)
            ]
            for (xFrac, period, phase) in flakes {
                let progress = ((t + phase).truncatingRemainder(dividingBy: period)) / period
                let y = progress * size.height
                context.fill(Path(ellipseIn: CGRect(x: size.width * xFrac, y: y, width: 2.5, height: 2.5)), with: .color(PandaColor.white.opacity(0.7)))
            }
        }
    }

    private func renderShadow(context: GraphicsContext, groundY: CGFloat) {
        let heightFactor = max(0, 1 - gameState.dinosaur.y / 60)
        let centerX = gameState.dinosaur.x + gameState.dinosaur.width / 2
        let width = 24 * heightFactor
        let shadowRect = CGRect(x: centerX - width / 2, y: groundY - 2, width: width, height: 4)
        context.fill(Path(ellipseIn: shadowRect), with: .color(PandaColor.white.opacity(0.12 * heightFactor)))
    }

    private func renderPanda(context: GraphicsContext, groundY: CGFloat) {
        var context = context
        let pandaHeight: CGFloat = 22 * (1 - gameState.dinosaur.duckLevel * 0.65)
        let pandaWidth: CGFloat = pandaHeight * 36 / 26
        let footY = groundY - gameState.dinosaur.y
        let rect = CGRect(x: gameState.dinosaur.x, y: footY - pandaHeight, width: pandaWidth, height: pandaHeight)
        let rotation: Double = gameState.dinosaur.isJumping ? -8 : 0

        if gameState.powerUpActive {
            let glowRect = rect.insetBy(dx: -5, dy: -5)
            context.stroke(
                Path(ellipseIn: glowRect),
                with: .color(PandaColor.greenMint.opacity(0.6)),
                lineWidth: 1.5
            )
        }

        PandaGraphics.drawPanda(&context, in: rect, rotationDegrees: rotation, accentColor: gameState.kinEarAccent)
    }

    private func renderObstacles(context: GraphicsContext, groundY: CGFloat, season: Season) {
        for (index, obstacle) in gameState.obstacles.enumerated() {
            // A falling Snow Pass icicle drops in from above the top of the play area down to
            // its resting spot — ease-in so it reads as accelerating under gravity.
            let dropEase = obstacle.fallProgress * obstacle.fallProgress
            let dropOffset = (1 - dropEase) * -groundY
            let rect = CGRect(x: obstacle.x, y: groundY - obstacle.height + dropOffset, width: obstacle.width, height: obstacle.height)

            switch gameState.world {
            case .bambooGrove:
                renderBambooStalk(context: context, rect: rect, index: index)
            case .mistTerraces:
                renderStone(context: context, rect: rect, index: index)
            case .snowPass:
                renderIcicle(context: context, rect: rect)
            case .lanternRow:
                renderLantern(context: context, rect: rect)
            case .ashHollow:
                renderScree(context: context, rect: rect)
            }
        }
    }

    /// Ambient icicles falling behind the panda in Snow Pass — decorative only, no collision.
    private func renderSkyIcicles(context: GraphicsContext, groundY: CGFloat) {
        guard gameState.world.mechanic == .overhead else { return }
        for icicle in gameState.skyIcicles {
            let fallFraction = min(1, icicle.y / groundY)
            let opacity = 1 - max(0, icicle.y - groundY) / GameConstants.skyIcicleMaxFall
            let rect = CGRect(x: icicle.x, y: icicle.y - 7, width: 3, height: 7 * fallFraction + 2)

            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()

            context.fill(path, with: .color(PandaColor.greenIce.opacity(0.35 * opacity)))
        }
    }

    private func renderBambooStalk(context: GraphicsContext, rect: CGRect, index: Int) {
        context.fill(
            Path(roundedRect: rect, cornerRadius: 2),
            with: .linearGradient(
                Gradient(colors: [PandaColor.green, PandaColor.greenDeep]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            )
        )

        let bandCount = max(1, Int(rect.height / 11))
        for band in 1...bandCount {
            let y = rect.minY + CGFloat(band) * (rect.height / CGFloat(bandCount + 1))
            context.fill(Path(CGRect(x: rect.minX, y: y, width: rect.width, height: 1)), with: .color(PandaColor.ink.opacity(0.5)))
        }

        let flagY = rect.minY + 2
        let pointsRight = index.isMultiple(of: 2)
        var flag = Path()
        if pointsRight {
            flag.move(to: CGPoint(x: rect.minX, y: flagY))
            flag.addLine(to: CGPoint(x: rect.minX + 11, y: flagY + 2.5))
            flag.addLine(to: CGPoint(x: rect.minX, y: flagY + 5))
        } else {
            flag.move(to: CGPoint(x: rect.maxX, y: flagY))
            flag.addLine(to: CGPoint(x: rect.maxX - 11, y: flagY + 2.5))
            flag.addLine(to: CGPoint(x: rect.maxX, y: flagY + 5))
        }
        flag.closeSubpath()
        context.fill(flag, with: .color(pointsRight ? PandaColor.greenPale : PandaColor.greenDeep))
    }

    private func renderStone(context: GraphicsContext, rect: CGRect, index: Int) {
        let color = index.isMultiple(of: 2) ? PandaColor.grey : Color(hex: 0xC3CAC3)
        context.fill(Path(roundedRect: rect, cornerRadius: rect.width * 0.3), with: .color(color))
        context.fill(
            Path(roundedRect: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.12), cornerRadius: rect.width * 0.2),
            with: .color(PandaColor.white.opacity(0.12))
        )
    }

    private func renderIcicle(context: GraphicsContext, rect: CGRect) {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [PandaColor.greenIce, PandaColor.greenMint]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            )
        )
        context.stroke(path, with: .color(PandaColor.white.opacity(0.4)), lineWidth: 0.5)
    }

    private func renderLantern(context: GraphicsContext, rect: CGRect) {
        let postWidth: CGFloat = 1
        context.fill(
            Path(CGRect(x: rect.midX - postWidth / 2, y: rect.minY, width: postWidth, height: rect.height * 0.4)),
            with: .color(PandaColor.white.opacity(0.3))
        )
        let bodyRect = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.35, width: rect.width, height: rect.height * 0.65)
        context.fill(Path(roundedRect: bodyRect, cornerRadius: rect.width * 0.25), with: .color(PandaColor.white.opacity(0.55)))
        context.fill(
            Path(ellipseIn: bodyRect.insetBy(dx: rect.width * 0.25, dy: bodyRect.height * 0.2)),
            with: .color(PandaColor.greenPale.opacity(0.65))
        )
    }

    private func renderScree(context: GraphicsContext, rect: CGRect) {
        let chunkCount = max(2, Int(rect.height / 10))
        for i in 0..<chunkCount {
            let h = rect.height / CGFloat(chunkCount)
            let chunkRect = CGRect(
                x: rect.minX + (i.isMultiple(of: 2) ? 0 : rect.width * 0.15),
                y: rect.maxY - CGFloat(i + 1) * h,
                width: rect.width * 0.85,
                height: h * 0.85
            )
            context.fill(Path(roundedRect: chunkRect, cornerRadius: 1.5), with: .color(PandaColor.white.opacity(0.16 + Double(i) * 0.04)))
        }
    }

    private func renderShoots(context: GraphicsContext, groundY: CGFloat) {
        for shoot in gameState.shoots {
            let center = CGPoint(x: shoot.x, y: groundY - shoot.groundHeight)
            let rect = CGRect(x: center.x - shoot.radius, y: center.y - shoot.radius, width: shoot.radius * 2, height: shoot.radius * 2)
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: PandaColor.greenPale.opacity(0.7), radius: 4))
                layer.fill(Path(ellipseIn: rect), with: .color(PandaColor.greenPale))
            }
        }
    }

    private func renderTerraces(context: GraphicsContext, size: CGSize, groundY: CGFloat, season: Season) {
        guard gameState.world.mechanic == .elevation else { return }

        let capColor: Color = {
            switch season {
            case .spring: return Color(hex: 0x8FD69B)
            case .summer: return PandaColor.green
            case .autumn: return PandaColor.greenMint
            case .winter: return PandaColor.white
            }
        }()
        let bodyColor: Color = {
            switch season {
            case .spring: return Color(hex: 0x92ACBA, opacity: 0.85)
            case .summer: return Color(hex: 0x8AB2B0, opacity: 0.85)
            case .autumn: return Color(hex: 0xA6B8C4, opacity: 0.7)
            case .winter: return Color(hex: 0xC4D8E4, opacity: 0.85)
            }
        }()

        let slabHeight: CGFloat = 18

        for (index, terrace) in gameState.terraces.enumerated() {
            let stepY = size.height - GameConstants.groundOffset - terrace.heightOffset
            guard stepY < size.height else { continue }

            // Autumn fog hides platforms further down the track — only the near ones read clearly.
            let fogFade: Double = season == .autumn ? max(0.3, 1 - Double(index) * 0.22) : 1.0

            let bodyRect = CGRect(x: terrace.x, y: stepY + 2.5, width: terrace.width, height: slabHeight)

            // Floating shadow cast into the gorge below — reads as "hovering", not "grounded".
            let shadowRect = CGRect(x: bodyRect.minX + bodyRect.width * 0.15, y: min(size.height - 3, bodyRect.maxY + 10), width: bodyRect.width * 0.7, height: 3)
            context.fill(Path(ellipseIn: shadowRect), with: .color(PandaColor.ink.opacity(0.28 * fogFade)))

            // Jagged rock underside instead of a flat slab, so it reads as a chunk of broken gorge wall.
            var rockPath = Path()
            rockPath.move(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY))
            rockPath.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.minY))
            rockPath.addLine(to: CGPoint(x: bodyRect.maxX - bodyRect.width * 0.14, y: bodyRect.minY + bodyRect.height * 0.62))
            rockPath.addLine(to: CGPoint(x: bodyRect.minX + bodyRect.width * 0.58, y: bodyRect.maxY))
            rockPath.addLine(to: CGPoint(x: bodyRect.minX + bodyRect.width * 0.34, y: bodyRect.minY + bodyRect.height * 0.66))
            rockPath.addLine(to: CGPoint(x: bodyRect.minX + bodyRect.width * 0.1, y: bodyRect.minY + bodyRect.height * 0.48))
            rockPath.closeSubpath()
            context.fill(rockPath, with: .color(bodyColor.opacity(fogFade)))

            context.fill(
                Path(CGRect(x: terrace.x, y: stepY, width: terrace.width, height: 2.5)),
                with: .color(capColor.opacity(fogFade))
            )

            if season == .winter {
                let drips: [CGFloat] = [0.18, 0.62]
                for dripFrac in drips {
                    let dripX = terrace.x + terrace.width * dripFrac
                    context.fill(
                        Path(CGRect(x: dripX, y: stepY + 2, width: 1, height: 7)),
                        with: .color(PandaColor.greenIce.opacity(0.6 * fogFade))
                    )
                }
            }
        }
    }

    private func renderOverheadHazards(context: GraphicsContext, currentTime: Date) {
        guard !gameState.overheadHazards.isEmpty else { return }
        let t = currentTime.timeIntervalSinceReferenceDate
        for hazard in gameState.overheadHazards {
            var path = Path()
            path.move(to: CGPoint(x: hazard.x, y: 0))
            path.addLine(to: CGPoint(x: hazard.x + hazard.width / 2, y: hazard.reach))
            path.addLine(to: CGPoint(x: hazard.x + hazard.width, y: 0))
            path.closeSubpath()

            switch gameState.world {
            case .lanternRow:
                let bodyHeight: CGFloat = hazard.isExtraLarge ? 13 : 8
                let bodyRect = CGRect(x: hazard.x, y: hazard.reach - bodyHeight, width: hazard.width, height: bodyHeight)
                let pivot = CGPoint(x: hazard.x + hazard.width / 2, y: 0)

                // Each lantern swings independently — a stable per-lantern phase (seeded from its
                // id, not its scrolling x) plus a slower period for the bigger, heavier ones.
                let phase = Double(hazard.id.hashValue.magnitude % 1000) / 1000 * .pi * 2
                let swingSpeed: Double = hazard.isExtraLarge ? 1.6 : 2.4
                let swingAmplitude: Double = hazard.isExtraLarge ? 5 : 9
                let swingAngle = sin(t * swingSpeed + phase) * swingAmplitude

                context.drawLayer { layer in
                    layer.translateBy(x: pivot.x, y: pivot.y)
                    layer.rotate(by: .degrees(swingAngle))
                    layer.translateBy(x: -pivot.x, y: -pivot.y)

                    layer.fill(Path(CGRect(x: hazard.x + hazard.width / 2 - 0.5, y: 0, width: 1, height: hazard.reach - bodyHeight)), with: .color(PandaColor.white.opacity(0.3)))
                    layer.addFilter(.shadow(color: PandaColor.green.opacity(0.6), radius: hazard.isExtraLarge ? 6 : 4))
                    layer.fill(Path(roundedRect: bodyRect, cornerRadius: 3), with: .color(PandaColor.green))
                    if hazard.isExtraLarge {
                        layer.stroke(Path(roundedRect: bodyRect.insetBy(dx: 1, dy: 1), cornerRadius: 2.5), with: .color(PandaColor.greenPale.opacity(0.8)), lineWidth: 1)
                    }
                }
            default:
                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [PandaColor.greenIce, PandaColor.greenMint]),
                        startPoint: CGPoint(x: hazard.x, y: 0),
                        endPoint: CGPoint(x: hazard.x, y: hazard.reach)
                    )
                )
            }
        }
    }

    private func renderGroundStability(context: GraphicsContext, size: CGSize, groundY: CGFloat, currentTime: Date) {
        guard gameState.world.mechanic == .unstable else { return }
        let pulse = gameState.groundStability < 0.4
            ? (0.5 + 0.5 * sin(currentTime.timeIntervalSinceReferenceDate * 10))
            : 0
        let alertOpacity = (1 - gameState.groundStability) * 0.25 + Double(pulse) * 0.15
        guard alertOpacity > 0.02 else { return }
        let rect = CGRect(x: gameState.dinosaur.x - 6, y: groundY - 2, width: gameState.dinosaur.width + 12, height: 4)
        context.fill(Path(ellipseIn: rect), with: .color(PandaColor.white.opacity(alertOpacity)))
    }

    private func renderHUD(context: GraphicsContext, size: CGSize, currentTime: Date) {
        var context = context

        // Score
        context.draw(
            Text("\(gameState.score)")
                .font(.numeral(size: 17, weight: .medium))
                .foregroundColor(PandaColor.white),
            at: CGPoint(x: 9 + 15, y: 9 + 8),
            anchor: .center
        )

        // Shoots collected
        let dotRect = CGRect(x: 9, y: 28, width: 5, height: 5)
        context.fill(Path(ellipseIn: dotRect), with: .color(PandaColor.greenPale))
        context.draw(
            Text("\(gameState.shootsCollected)")
                .font(.numeral(size: 9))
                .foregroundColor(PandaColor.white.opacity(0.6)),
            at: CGPoint(x: 9 + 8 + 8, y: 28 + 3),
            anchor: .leading
        )

        renderChargeRing(context: &context, size: size)
        renderHoldButton(context: &context, size: size)
        renderSeasonBanner(context: &context, size: size, currentTime: currentTime)
        renderSeasonProgressBar(context: &context, size: size)
        renderLanternTip(context: &context, size: size, currentTime: currentTime)
    }

    /// First-run nudge for Lantern Row: turn the Digital Crown to shrink under the lanterns.
    private func renderLanternTip(context: inout GraphicsContext, size: CGSize, currentTime: Date) {
        guard let hideAt = lanternTipVisibleUntil, currentTime < hideAt else { return }

        let remaining = hideAt.timeIntervalSince(currentTime)
        let fadeWindow: TimeInterval = 0.4
        let opacity: Double
        if remaining < fadeWindow {
            opacity = remaining / fadeWindow
        } else if GameConstants.lanternTipDuration - remaining < fadeWindow {
            opacity = (GameConstants.lanternTipDuration - remaining) / fadeWindow
        } else {
            opacity = 1
        }

        let rect = CGRect(x: size.width * 0.5 - 68, y: size.height * 0.5 - 16, width: 136, height: 32)
        context.fill(Path(roundedRect: rect, cornerRadius: 10), with: .color(PandaColor.ink.opacity(0.85 * opacity)))
        context.stroke(Path(roundedRect: rect, cornerRadius: 10), with: .color(PandaColor.green.opacity(0.5 * opacity)), lineWidth: 1)

        context.draw(
            Text("↕ TURN CROWN")
                .font(.heading(size: 9, weight: .semibold))
                .foregroundColor(PandaColor.white.opacity(opacity)),
            at: CGPoint(x: rect.midX, y: rect.midY - 6),
            anchor: .center
        )
        context.draw(
            Text("to shrink under lanterns")
                .font(.numeral(size: 7))
                .foregroundColor(PandaColor.white.opacity(0.6 * opacity)),
            at: CGPoint(x: rect.midX, y: rect.midY + 8),
            anchor: .center
        )
    }

    private func renderChargeRing(context: inout GraphicsContext, size: CGSize) {
        let ringRect = CGRect(x: size.width - 9 - 26, y: 8, width: 26, height: 26)
        let center = CGPoint(x: ringRect.midX, y: ringRect.midY)

        context.stroke(Path(ellipseIn: ringRect), with: .color(PandaColor.white.opacity(0.12)), style: StrokeStyle(lineWidth: 2.5))

        let fraction = gameState.powerCharge / 100
        if fraction > 0 {
            let full = Path(ellipseIn: ringRect)
            let trimmed = full.trimmedPath(from: 0, to: fraction)
            let rotate = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: -.pi / 2)
                .translatedBy(x: -center.x, y: -center.y)
            context.stroke(
                trimmed.applying(rotate),
                with: .color(PandaColor.green),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
        }

        context.draw(
            Text("\(Int(gameState.powerCharge))")
                .font(.numeral(size: 8, weight: .medium))
                .foregroundColor(PandaColor.green),
            at: center,
            anchor: .center
        )
    }

    private func renderHoldButton(context: inout GraphicsContext, size: CGSize) {
        let isReady = gameState.powerCharge >= 100
        let rect = CGRect(x: size.width - 9 - 22, y: 39, width: 22, height: 22)
        let opacity = isReady ? 1.0 : 0.4

        context.fill(
            Path(roundedRect: rect, cornerRadius: 7),
            with: .color(PandaColor.green.opacity((isReady ? 0.16 : 0.08)))
        )
        context.stroke(
            Path(roundedRect: rect, cornerRadius: 7),
            with: .color(PandaColor.green.opacity(opacity)),
            lineWidth: 0.5
        )

        var triangle = Path()
        let t = CGRect(x: rect.midX - 4, y: rect.midY - 4, width: 8, height: 8)
        triangle.move(to: CGPoint(x: t.midX, y: t.minY))
        triangle.addLine(to: CGPoint(x: t.maxX, y: t.maxY))
        triangle.addLine(to: CGPoint(x: t.minX, y: t.maxY))
        triangle.closeSubpath()
        context.fill(triangle, with: .color(PandaColor.green.opacity(opacity)))

        context.draw(
            Text("HOLD")
                .font(.numeral(size: 6.5))
                .foregroundColor(PandaColor.green.opacity(opacity * 0.85)),
            at: CGPoint(x: rect.midX, y: rect.maxY + 6),
            anchor: .center
        )
    }

    private func renderSeasonBanner(context: inout GraphicsContext, size: CGSize, currentTime: Date) {
        guard let hideAt = gameState.seasonBannerVisibleUntil, currentTime < hideAt else { return }

        let remaining = hideAt.timeIntervalSince(currentTime)
        let fadeWindow: TimeInterval = 0.4
        let opacity: Double
        if remaining < fadeWindow {
            opacity = remaining / fadeWindow
        } else if GameConstants.seasonBannerDuration - remaining < fadeWindow {
            opacity = (GameConstants.seasonBannerDuration - remaining) / fadeWindow
        } else {
            opacity = 1
        }

        let text = "\(gameState.season.displayName) · \(gameState.metersTraveled)m"
        let label = Text(text)
            .font(.numeral(size: 8, weight: .semibold))
            .foregroundColor(PandaColor.greenIce.opacity(opacity))

        context.draw(
            label,
            at: CGPoint(x: size.width / 2, y: 64),
            anchor: .center
        )
    }

    private func renderSeasonProgressBar(context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(x: 9, y: size.height - 8, width: size.width - 18, height: 2)
        context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(PandaColor.white.opacity(0.1)))

        let fillWidth = rect.width * gameState.seasonSegmentProgress
        guard fillWidth > 0 else { return }
        let fillRect = CGRect(x: rect.minX, y: rect.minY, width: fillWidth, height: rect.height)
        context.fill(
            Path(roundedRect: fillRect, cornerRadius: 1),
            with: .linearGradient(
                Gradient(colors: [PandaColor.green, PandaColor.greenMint, PandaColor.green]),
                startPoint: CGPoint(x: fillRect.minX, y: 0),
                endPoint: CGPoint(x: fillRect.maxX, y: 0)
            )
        )
    }

    private func renderFloatingRewards(context: GraphicsContext, currentTime: Date) {
        for reward in floatingRewards {
            let opacity = reward.opacity(at: currentTime)
            guard opacity > 0 else { continue }

            let yOffset = reward.yOffset(at: currentTime)

            context.draw(
                Text(reward.text)
                    .font(.numeral(size: 10, weight: .semibold))
                    .foregroundColor(reward.color.opacity(opacity)),
                at: CGPoint(x: reward.startX, y: reward.startY + yOffset)
            )
        }
    }
}
