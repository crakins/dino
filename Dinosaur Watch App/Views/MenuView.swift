import SwiftUI
import WatchKit

struct MenuView: View {
    let highScore: Int
    let streak: Int
    let playerLevel: Int
    let coins: Int
    let unseenUnlocks: Int
    let questProgress: Int
    let questTarget: Int
    let xpFraction: Double
    let onStart: () -> Void
    let onShop: () -> Void
    let onQuest: () -> Void
    let onProfile: () -> Void

    init(
        highScore: Int,
        streak: Int,
        playerLevel: Int,
        coins: Int,
        unseenUnlocks: Int = 0,
        questProgress: Int = 1,
        questTarget: Int = 3,
        xpFraction: Double = 0,
        onStart: @escaping () -> Void,
        onShop: @escaping () -> Void,
        onQuest: @escaping () -> Void = {},
        onProfile: @escaping () -> Void = {}
    ) {
        self.highScore = highScore
        self.streak = streak
        self.playerLevel = playerLevel
        self.coins = coins
        self.unseenUnlocks = unseenUnlocks
        self.questProgress = questProgress
        self.questTarget = questTarget
        self.xpFraction = xpFraction
        self.onStart = onStart
        self.onShop = onShop
        self.onQuest = onQuest
        self.onProfile = onProfile
    }

    var body: some View {
        VStack(spacing: 0) {
            BannerView(coins: coins, playerLevel: playerLevel, xpFraction: xpFraction, onProfile: onProfile)
                .frame(height: 62)

            VStack(spacing: 5) {
                RunCard(highScore: highScore, season: currentSeason, action: onStart)
                QuestCard(progress: questProgress, target: questTarget, action: onQuest)
                MarketCard(unseenUnlocks: unseenUnlocks, action: onShop)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PandaColor.ink)
        .ignoresSafeArea()
    }

    private var currentSeason: String {
        switch Calendar.current.component(.month, from: Date()) {
        case 3...5: return "SPRING"
        case 6...8: return "SUMMER"
        case 9...11: return "AUTUMN"
        default: return "WINTER"
        }
    }
}

// MARK: - Banner

private struct BannerView: View {
    let coins: Int
    let playerLevel: Int
    let xpFraction: Double
    let onProfile: () -> Void

    @State private var dashPhase: CGFloat = 0
    @State private var bob: CGFloat = 0
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: isLuminanceReduced
                    ? [PandaColor.ink, PandaColor.ink]
                    : [PandaColor.bannerTop, PandaColor.ink],
                startPoint: .top,
                endPoint: .bottom
            )

            // Wordmark
            VStack(alignment: .leading, spacing: 0) {
                Text("PANDA")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(PandaColor.white)
                Text("PANDA")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(PandaColor.green)
            }
            .lineSpacing(-2)
            .padding(.leading, 10)
            .padding(.top, 18)

            // Coin readout + level chip
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(PandaColor.greenMint)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(PandaColor.ink.opacity(0.35))
                            .frame(width: 3.6, height: 3.6)
                    }
                    Text("\(coins)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(PandaColor.greenMint)
                }

                Button(action: onProfile) {
                    HStack(spacing: 4) {
                        Text("LV \(playerLevel)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(PandaColor.green)
                        Capsule()
                            .fill(PandaColor.white.opacity(0.15))
                            .frame(width: 16, height: 2)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(PandaColor.green)
                                    .frame(width: 16 * max(0, min(1, xpFraction)), height: 2)
                            }
                        Text("›")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(PandaColor.green.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(PandaColor.green.opacity(0.14))
                            .overlay(Capsule().stroke(PandaColor.green.opacity(0.55), lineWidth: 0.5))
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 10)
            .padding(.top, 8)

            GeometryReader { proxy in
                ZStack(alignment: .bottomLeading) {
                    // Ground line
                    Rectangle()
                        .fill(PandaColor.green.opacity(0.5))
                        .frame(height: 1)
                        .padding(.bottom, 9)
                        .frame(maxWidth: .infinity, alignment: .bottom)

                    // Scrolling ground dashes
                    Canvas { context, size in
                        let dashHeight: CGFloat = 2
                        let y = size.height - 4
                        var path = Path()
                        path.move(to: CGPoint(x: -20 + dashPhase, y: y))
                        path.addLine(to: CGPoint(x: size.width + 20, y: y))
                        context.stroke(
                            path,
                            with: .color(PandaColor.green.opacity(0.5)),
                            style: StrokeStyle(lineWidth: dashHeight, dash: [10, 10])
                        )
                    }
                    .frame(height: 4, alignment: .bottom)

                    // Panda sprite
                    PandaSprite()
                        .frame(width: 28, height: 20)
                        .offset(x: 112, y: -10 - bob)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
            }
        }
        .clipped()
        .onAppear { startAnimations() }
        .onDisappear { stopAnimations() }
        .onChange(of: isLuminanceReduced) { _, reduced in
            if reduced { stopAnimations() } else { startAnimations() }
        }
    }

    private func startAnimations() {
        guard !isLuminanceReduced else { return }
        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
            dashPhase = 40
        }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            bob = 1.5
        }
    }

    private func stopAnimations() {
        dashPhase = 0
        bob = 0
    }
}

// MARK: - Panda sprite (Canvas)

private struct PandaSprite: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 36, size.height / 26)
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }
            func rounded(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale), cornerRadius: r * scale)
            }
            func circle(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - r) * scale, y: (cy - r) * scale, width: 2 * r * scale, height: 2 * r * scale))
            }
            func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - rx) * scale, y: (cy - ry) * scale, width: 2 * rx * scale, height: 2 * ry * scale))
            }

            context.fill(circle(cx: 5.5, cy: 12, r: 2.4), with: .color(PandaColor.white))
            context.fill(rounded(x: 8, y: 16, w: 4.5, h: 9, r: 2.2), with: .color(PandaColor.pandaBlack))
            context.fill(rounded(x: 6, y: 8, w: 18, h: 11, r: 5), with: .color(PandaColor.white))
            context.fill(rounded(x: 9.5, y: 8, w: 6.5, h: 9, r: 3.2), with: .color(PandaColor.pandaBlack))
            context.fill(circle(cx: 24.6, cy: 6.6, r: 2.7), with: .color(PandaColor.pandaBlack))
            context.fill(circle(cx: 27, cy: 12, r: 6), with: .color(PandaColor.white))
            context.fill(ellipse(cx: 28.6, cy: 10.8, rx: 2, ry: 2.4), with: .color(PandaColor.pandaBlack))
            context.fill(circle(cx: 28.8, cy: 10.4, r: 0.7), with: .color(PandaColor.white))
            context.fill(circle(cx: 32, cy: 13, r: 1.1), with: .color(PandaColor.pandaBlack))
            context.fill(rounded(x: 16.5, y: 16, w: 4.5, h: 9, r: 2.2), with: .color(PandaColor.pandaBlack))
            _ = pt
        }
    }
}

// MARK: - Cards

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct RunCard: View {
    let highScore: Int
    let season: String
    let action: () -> Void

    var body: some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Run")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(PandaColor.ink)
                    Text("BEST \(highScore) · \(season)")
                        .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                        .foregroundColor(PandaColor.ink.opacity(0.62))
                }
                Spacer()
                Text("→")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(PandaColor.ink.opacity(0.7))
            }
            .padding(.horizontal, 11)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(PandaColor.green)
            .cornerRadius(11)
        }
        .buttonStyle(CardPressStyle())
    }
}

private struct QuestCard: View {
    let progress: Int
    let target: Int
    let action: () -> Void

    private var fraction: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(progress) / CGFloat(target)
    }

    var body: some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today's quest")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PandaColor.white)
                    Text("CLEAR \(target) HOLLOWS · \(progress)/\(target)")
                        .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                        .foregroundColor(PandaColor.white.opacity(0.45))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(PandaColor.green.opacity(0.3), lineWidth: 1.5)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(PandaColor.green, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 11)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(PandaColor.inkRaised)
            .cornerRadius(11)
        }
        .buttonStyle(CardPressStyle())
    }
}

private struct MarketCard: View {
    let unseenUnlocks: Int
    let action: () -> Void

    var body: some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Market")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PandaColor.white)
                    Text("\(unseenUnlocks) NEW UNLOCKS")
                        .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                        .foregroundColor(PandaColor.white.opacity(0.45))
                }
                Spacer()
                if unseenUnlocks > 0 {
                    Circle()
                        .fill(PandaColor.greenMint)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(PandaColor.inkRaised)
            .cornerRadius(11)
        }
        .buttonStyle(CardPressStyle())
    }
}
