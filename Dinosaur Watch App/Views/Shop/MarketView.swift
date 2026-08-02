import SwiftUI
import WatchKit

struct MarketView: View {
    var playerDataManager: PlayerDataManager
    let onClose: () -> Void

    @State private var tab: MarketTab = .worlds
    @State private var selectedKin: Kin?
    @State private var selectedWorld: World?

    enum MarketTab {
        case kin, worlds
    }

    var body: some View {
        Group {
            if let kin = selectedKin {
                KinDetailView(kin: kin, playerDataManager: playerDataManager, onBack: { selectedKin = nil })
            } else if let world = selectedWorld {
                WorldDetailView(world: world, playerDataManager: playerDataManager, onBack: { selectedWorld = nil })
            } else {
                gridView
            }
        }
    }

    private var gridView: some View {
        VStack(alignment: .leading, spacing: 0) {
            MarketBackButton(label: "Home", action: onClose)
                .padding(.horizontal, 8)

            HStack {
                Text("Market")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(0.2)
                    .foregroundColor(PandaColor.white)
                Spacer()
                HStack(spacing: 3) {
                    CoinDot(size: 9)
                    Text("\(playerDataManager.playerData.coins)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(PandaColor.greenMint)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)
            .padding(.bottom, 5)

            HStack(spacing: 3) {
                tabButton("Pandas", isSelected: tab == .kin) { tab = .kin }
                tabButton("Worlds", isSelected: tab == .worlds) { tab = .worlds }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                    if tab == .kin {
                        ForEach(Kin.allCases) { kin in
                            kinTile(kin)
                        }
                    } else {
                        ForEach(World.allCases) { world in
                            worldTile(world)
                        }
                        teaserTile
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PandaColor.ink)
        .ignoresSafeArea()
    }

    private func tabButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? PandaColor.ink : PandaColor.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 18)
                .background(isSelected ? PandaColor.white : PandaColor.inkRaised)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Kin tiles

    private func kinTile(_ kin: Kin) -> some View {
        let data = playerDataManager.playerData
        let isOwned = data.owns(kin)
        let isEquipped = data.equippedKin == kin.rawValue

        return MarketTile(
            title: kin.displayName,
            caption: kin.perkTag ?? "STAGE \(kin.stage) OF 5",
            isEquipped: isEquipped,
            badge: badge(isOwned: isOwned, isEquipped: isEquipped, canPurchase: data.canPurchase(kin), cost: kin.coinCost, requiredLevel: kin.requiredPlayerLevel, hasLevel: data.playerLevel >= kin.requiredPlayerLevel),
            glowColor: kin.earAccent
        ) {
            GeometryReader { geo in
                Canvas { context, size in
                    let rect = CGRect(x: 0, y: -6, width: size.width, height: size.height).insetBy(dx: size.width * 0.28, dy: size.height * 0.1)
                    PandaGraphics.drawHeadMark(&context, in: rect, earColor: kin.earAccent)
                }
            }
        }
        .onTapGesture { selectedKin = kin }
    }

    // MARK: - World tiles

    private func worldTile(_ world: World) -> some View {
        let data = playerDataManager.playerData
        let isOwned = data.owns(world)
        let isEquipped = data.equippedWorld == world.rawValue

        return MarketTile(
            title: world.displayName,
            caption: world.hazardName,
            isEquipped: isEquipped,
            badge: badge(isOwned: isOwned, isEquipped: isEquipped, canPurchase: data.canPurchase(world), cost: world.coinCost, requiredLevel: world.requiredPlayerLevel, hasLevel: data.playerLevel >= world.requiredPlayerLevel),
            glowColor: world.accentColor
        ) {
            WorldTileScene(world: world)
        }
        .onTapGesture { selectedWorld = world }
    }

    private var teaserTile: some View {
        VStack {
            Spacer()
            Text("ONE MORE\nWORLD AT LV18")
                .multilineTextAlignment(.center)
                .font(.system(size: 7.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.32))
            Spacer()
        }
        .frame(height: 68)
        .frame(maxWidth: .infinity)
        .background(PandaColor.inkSunken)
        .cornerRadius(9)
    }

    private func badge(isOwned: Bool, isEquipped: Bool, canPurchase: Bool, cost: Int, requiredLevel: Int, hasLevel: Bool) -> MarketBadge {
        if isEquipped { return .equipped }
        if isOwned { return .owned }
        if !hasLevel { return .level(requiredLevel, met: false) }
        return .price(cost, canAfford: canPurchase)
    }
}

// MARK: - Shared chrome

struct MarketBackButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text("‹")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                Text(label)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
            }
            .foregroundColor(PandaColor.green)
            .frame(height: 20)
        }
        .buttonStyle(.plain)
    }
}

struct CoinDot: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(PandaColor.greenMint)
            Circle().fill(PandaColor.ink.opacity(0.35)).frame(width: size * 0.45, height: size * 0.45)
        }
        .frame(width: size, height: size)
    }
}

private enum MarketBadge {
    case equipped
    case owned
    case price(Int, canAfford: Bool)
    case level(Int, met: Bool)
}

private struct MarketTile<Scene: View>: View {
    let title: String
    let caption: String
    let isEquipped: Bool
    let badge: MarketBadge
    let glowColor: Color
    @ViewBuilder var scene: () -> Scene

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RadialGradient(colors: [glowColor.opacity(0.14), .clear], center: UnitPoint(x: 0.7, y: 0.25), startRadius: 0, endRadius: 55)

            scene()

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .foregroundColor(PandaColor.white)
                    .lineLimit(1)
                Text(caption)
                    .font(.system(size: 6.5, design: .monospaced))
                    .tracking(0.3)
                    .foregroundColor(PandaColor.white.opacity(0.42))
                    .lineLimit(1)
            }
            .padding(5)

            badgeView
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(height: 68)
        .background(PandaColor.inkSunken)
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(isEquipped ? PandaColor.green : Color.clear, lineWidth: 1)
        )
    }

    @ViewBuilder private var badgeView: some View {
        switch badge {
        case .equipped:
            Circle().fill(PandaColor.green).frame(width: 5, height: 5)
        case .owned:
            Text("OWNED")
                .font(.system(size: 6.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.5))
        case .price(let cost, let canAfford):
            HStack(spacing: 2) {
                CoinDot(size: 7)
                Text("\(cost)")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(canAfford ? PandaColor.greenMint : PandaColor.white.opacity(0.35))
            }
        case .level(let level, let met):
            Text("LV \(level)")
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(met ? PandaColor.greenMint : PandaColor.white.opacity(0.35))
        }
    }
}

struct WorldTileScene: View {
    let world: World

    private var season: Season {
        switch Calendar.current.component(.month, from: Date()) {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    private var skyColors: [Color] {
        switch season {
        case .spring: return [Color(hex: 0x2A4A5E), Color(hex: 0x3E6478)]
        case .summer: return [Color(hex: 0x1E4A55), Color(hex: 0x2E6672)]
        case .autumn: return [Color(hex: 0x33485C), Color(hex: 0x4C6478)]
        case .winter: return [Color(hex: 0x3D5C73), Color(hex: 0x5C808F)]
        }
    }

    var body: some View {
        Canvas { context, size in
            let groundY = size.height * 0.56
            let hasSky = world == .bambooGrove || world == .mistTerraces

            if hasSky {
                context.fill(
                    Path(CGRect(x: 0, y: 0, width: size.width, height: groundY)),
                    with: .linearGradient(Gradient(colors: skyColors), startPoint: .zero, endPoint: CGPoint(x: 0, y: groundY))
                )
            } else if world != .mistTerraces {
                context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 1)), with: .color(world.accentColor.opacity(0.6)))
            }

            switch world {
            case .bambooGrove:
                bambooBackdrop(context: context, size: size, groundY: groundY)
                context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 1)), with: .color(PandaColor.green))
                stalk(context: context, x: 9, groundY: groundY, h: 20, color: Color(hex: 0x8FD69B), flagRight: true)
                stalk(context: context, x: 15, groundY: groundY, h: 14, color: PandaColor.green, flagRight: nil)
                stalk(context: context, x: 31, groundY: groundY, h: 17, color: Color(hex: 0x8FD69B), flagRight: false)

            case .mistTerraces:
                mistBackdrop(context: context, size: size, groundY: groundY)
                platform(context: context, x: 6, groundY: groundY, w: 18, h: 9, color: PandaColor.grey)
                platform(context: context, x: 32, groundY: groundY - 8, w: 15, h: 9, color: Color(hex: 0xC3CAC3))
                jumpArc(context: context, from: CGPoint(x: 22, y: groundY - 10), to: CGPoint(x: 34, y: groundY - 18))

            case .snowPass:
                fallingIcicle(context: context, x: 11, y: 6, w: 5, h: 12, color: PandaColor.greenMint)
                fallingIcicle(context: context, x: 26, y: 6, w: 4, h: 9, color: PandaColor.greenIce)

            case .lanternRow:
                lantern(context: context, x: 14, groundY: groundY)

            case .ashHollow:
                scree(context: context, groundY: groundY)
            }

            if hasSky {
                // Vignette so the mini-scene fades into the card background instead of hard-cutting.
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0.62),
                            .init(color: PandaColor.inkSunken, location: 0.88)
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }
        }
    }

    private func bambooBackdrop(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        let heights: [CGFloat] = [10, 15, 8, 18, 11, 20, 9, 16]
        var x: CGFloat = 3
        var i = 0
        while x < size.width {
            let h = heights[i % heights.count]
            let color = i.isMultiple(of: 3) ? PandaColor.green.opacity(0.28) : PandaColor.green.opacity(0.18)
            context.fill(Path(CGRect(x: x, y: groundY - h, width: i.isMultiple(of: 3) ? 2 : 1, height: h)), with: .color(color))
            x += 7.5
            i += 1
        }
    }

    private func mistBackdrop(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        func ridge(height: CGFloat, opacity: Double) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: groundY))
            let step = size.width / 6
            for i in 0...6 {
                let x = CGFloat(i) * step
                let peak = groundY - height * (i.isMultiple(of: 2) ? 1 : 0.55)
                path.addLine(to: CGPoint(x: x, y: peak))
            }
            path.addLine(to: CGPoint(x: size.width, y: groundY))
            path.closeSubpath()
            return path
        }
        context.fill(ridge(height: 16, opacity: 0.3), with: .color(Color(hex: 0x92ACBA, opacity: 0.34)))
        context.fill(ridge(height: 11, opacity: 0.4), with: .color(Color(hex: 0xC4D8E4, opacity: 0.26)))
    }

    private func stalk(context: GraphicsContext, x: CGFloat, groundY: CGFloat, h: CGFloat, color: Color, flagRight: Bool?) {
        let rect = CGRect(x: x, y: groundY - h, width: 3, height: h)
        context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color))
        context.fill(Path(CGRect(x: rect.minX, y: rect.minY + h * 0.45, width: rect.width, height: 1)), with: .color(PandaColor.ink.opacity(0.6)))

        guard let flagRight else { return }
        var flag = Path()
        if flagRight {
            flag.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
            flag.addLine(to: CGPoint(x: rect.minX + 7, y: rect.minY + 2.5))
            flag.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 4))
        } else {
            flag.move(to: CGPoint(x: rect.maxX, y: rect.minY + 3))
            flag.addLine(to: CGPoint(x: rect.maxX - 7, y: rect.minY + 4.5))
            flag.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 6))
        }
        flag.closeSubpath()
        context.fill(flag, with: .color(flagRight ? Color(hex: 0xA8D8B0) : PandaColor.greenDeep))
    }

    private func platform(context: GraphicsContext, x: CGFloat, groundY: CGFloat, w: CGFloat, h: CGFloat, color: Color) {
        let rect = CGRect(x: x, y: groundY - h, width: w, height: h)
        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
        context.fill(Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1.5)), with: .color(PandaColor.white.opacity(0.4)))
    }

    private func jumpArc(context: GraphicsContext, from: CGPoint, to: CGPoint) {
        var path = Path()
        let control = CGPoint(x: (from.x + to.x) / 2, y: min(from.y, to.y) - 6)
        path.move(to: from)
        path.addQuadCurve(to: to, control: control)
        context.stroke(path, with: .color(PandaColor.white.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
    }

    private func fallingIcicle(context: GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + w / 2, y: y + h))
        path.addLine(to: CGPoint(x: x + w, y: y))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    private func lantern(context: GraphicsContext, x: CGFloat, groundY: CGFloat) {
        context.fill(Path(CGRect(x: x + 5, y: groundY - 22, width: 1, height: 10)), with: .color(PandaColor.white.opacity(0.3)))
        let bodyRect = CGRect(x: x, y: groundY - 12, width: 12, height: 9)
        context.fill(Path(roundedRect: bodyRect, cornerRadius: 2), with: .color(PandaColor.white.opacity(0.55)))
        context.fill(Path(ellipseIn: bodyRect.insetBy(dx: 3, dy: 2)), with: .color(PandaColor.greenPale.opacity(0.6)))
    }

    private func scree(context: GraphicsContext, groundY: CGFloat) {
        let chunks: [(CGFloat, CGFloat, CGFloat)] = [(12, 6, 6), (26, 5, 5), (19, 4, 10)]
        for (x, size, yOffset) in chunks {
            let rect = CGRect(x: x, y: groundY - yOffset, width: size, height: size)
            context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(PandaColor.white.opacity(0.14)))
        }
    }
}
