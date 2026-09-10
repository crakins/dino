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
        ZStack {
            // Only the background bleeds into the unsafe/rounded-corner region — the top
            // row's level/coin chips must stay inset or they land in the bezel's touch
            // dead-zone.
            PandaColor.ink.ignoresSafeArea()
            content
        }
    }

    // Every fixed size below is scaled by the watch's actual available height so the bottom
    // row (Market/Quest) never gets pushed past the visible area and clipped by the bezel on
    // smaller watch sizes (40/41mm) — 250pt is the ~45/46mm baseline the design was made at.
    private var content: some View {
        GeometryReader { geo in
            let scale = max(0.74, min(1, geo.size.height / 250))

            VStack(spacing: 0) {
                topRow

                VStack(spacing: 4 * scale) {
                    PandaFaceIcon()
                        .frame(width: 38 * scale, height: 29 * scale)

                    VStack(spacing: -10 * scale) {
                        Text("PANDA")
                            .font(.heading(size: 40 * scale, weight: .heavy))
                            .foregroundColor(PandaColor.white)
                        Text("PANDA")
                            .font(.heading(size: 40 * scale, weight: .heavy))
                            .foregroundColor(PandaColor.green)
                    }
                }
                .padding(.top, 2 * scale)

                infoRow
                    .padding(.top, 4 * scale)

                streakRow
                    .padding(.top, 4 * scale)

                Spacer(minLength: 6 * scale)

                RunButton(action: onStart, height: 42 * scale)

                HStack(spacing: 6) {
                    PillButton(title: "Market", dot: unseenUnlocks > 0 ? .filled(PandaColor.greenMint) : nil, height: 30 * scale, action: onShop)
                    PillButton(title: "Quest", dot: questProgress >= questTarget ? .filled(PandaColor.green) : .outline(PandaColor.white.opacity(0.35)), height: 30 * scale, action: onQuest)
                }
                .padding(.top, 5 * scale)
            }
            .padding(.horizontal, 10)
            .padding(.top, -8)
            .padding(.bottom, 8)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // Level and coins share a single chip, entirely on the left — the system clock owns the
    // top-right corner on every watch face, so rather than race it there with a second
    // element, this frees that whole corner and keeps both stats together on the side that's
    // actually ours.
    private var topRow: some View {
        HStack {
            Button(action: onProfile) {
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Text("★")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(PandaColor.white.opacity(0.8))
                        Text("LV \(playerLevel)")
                            .font(.numeral(size: 9.5, weight: .semibold))
                            .foregroundColor(PandaColor.white.opacity(0.85))
                    }

                    Capsule()
                        .fill(PandaColor.white.opacity(0.18))
                        .frame(width: 1, height: 10)

                    HStack(spacing: 4) {
                        CoinDot(size: 9)
                        Text("\(coins)")
                            .font(.numeral(size: 9.5, weight: .medium))
                            .foregroundColor(PandaColor.greenMint)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(PandaColor.inkRaised)
                        .overlay(Capsule().stroke(PandaColor.white.opacity(0.18), lineWidth: 0.5))
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var infoRow: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(PandaColor.green)
                .frame(width: 5, height: 5)
            Text("\(currentSeason) · BEST \(highScore)")
                .font(.numeral(size: 8.5, weight: .regular))
                .foregroundColor(PandaColor.white.opacity(0.55))
        }
    }

    private var streakRow: some View {
        HStack {
            Text("\(streak) DAY STREAK")
                .font(.numeral(size: 8.5, weight: .semibold))
                .foregroundColor(PandaColor.white.opacity(0.7))
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(i < min(streak, 7) ? PandaColor.green : PandaColor.white.opacity(0.15))
                        .frame(width: 4.5, height: 4.5)
                }
            }
        }
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

// MARK: - Panda face icon

private struct PandaFaceIcon: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 34, size.height / 26)
            func circle(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - r) * scale, y: (cy - r) * scale, width: 2 * r * scale, height: 2 * r * scale))
            }
            func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - rx) * scale, y: (cy - ry) * scale, width: 2 * rx * scale, height: 2 * ry * scale))
            }

            // Ears
            context.fill(circle(cx: 6, cy: 5, r: 4.2), with: .color(PandaColor.pandaBlack))
            context.fill(circle(cx: 28, cy: 5, r: 4.2), with: .color(PandaColor.pandaBlack))
            // Head
            context.fill(circle(cx: 17, cy: 13, r: 11), with: .color(PandaColor.white))
            // Eye patches
            context.fill(ellipse(cx: 11, cy: 12, rx: 3.2, ry: 4), with: .color(PandaColor.pandaBlack))
            context.fill(ellipse(cx: 23, cy: 12, rx: 3.2, ry: 4), with: .color(PandaColor.pandaBlack))
            // Eyes
            context.fill(circle(cx: 11, cy: 12.5, r: 1), with: .color(PandaColor.white))
            context.fill(circle(cx: 23, cy: 12.5, r: 1), with: .color(PandaColor.white))
            // Nose
            context.fill(ellipse(cx: 17, cy: 17.5, rx: 1.6, ry: 1.1), with: .color(PandaColor.pandaBlack))
        }
    }
}

// MARK: - Buttons

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct RunButton: View {
    let action: () -> Void
    var height: CGFloat = 42

    var body: some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            action()
        } label: {
            Text("RUN")
                .font(.heading(size: 16, weight: .heavy))
                .foregroundColor(PandaColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(PandaColor.green)
                .cornerRadius(14)
        }
        .buttonStyle(CardPressStyle())
    }
}

/// A status circle next to a pill button's label — filled means done/available, outline means
/// still in progress, so the button communicates state at a glance without opening the screen.
private enum PillDot {
    case filled(Color)
    case outline(Color)
}

private struct PillButton: View {
    let title: String
    var dot: PillDot? = nil
    var height: CGFloat = 30
    let action: () -> Void

    var body: some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            action()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.heading(size: 11.5, weight: .semibold))
                    .foregroundColor(PandaColor.white)
                switch dot {
                case .filled(let color):
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                case .outline(let color):
                    Circle()
                        .stroke(color, lineWidth: 1)
                        .frame(width: 5, height: 5)
                case nil:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Capsule()
                    .fill(PandaColor.inkRaised)
                    .overlay(Capsule().stroke(PandaColor.white.opacity(0.14), lineWidth: 0.5))
            )
        }
        .buttonStyle(CardPressStyle())
    }
}
