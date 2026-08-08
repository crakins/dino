import SwiftUI

struct ProfileView: View {
    let playerData: PlayerData
    let highScore: Int
    let streak: Int
    let onClose: () -> Void

    @State private var selectedBadge: Badge?

    private var unlockedBadges: [Badge] {
        Badge.all.filter { $0.isUnlocked(playerData, highScore, streak) }
    }

    private var featuredBadge: Badge {
        selectedBadge ?? unlockedBadges.last ?? Badge.all[0]
    }

    /// The next Kin or World that becomes purchasable at a higher level, if any.
    private var nextUnlock: (name: String, level: Int)? {
        let lockedKin = Kin.allCases
            .filter { !playerData.owns($0) && $0.requiredPlayerLevel > playerData.playerLevel }
            .map { (name: $0.displayName, level: $0.requiredPlayerLevel) }
        let lockedWorlds = World.allCases
            .filter { !playerData.owns($0) && $0.requiredPlayerLevel > playerData.playerLevel }
            .map { (name: $0.displayName, level: $0.requiredPlayerLevel) }
        return (lockedKin + lockedWorlds).min { $0.level < $1.level }
    }

    var body: some View {
        ZStack {
            // Only the background bleeds into the unsafe/rounded-corner region — the close
            // button in the top-right corner must stay inset or it lands in the bezel's
            // touch dead-zone.
            PandaColor.ink.ignoresSafeArea()
            content
        }
        .onAppear {
            selectedBadge = unlockedBadges.last
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                levelSection
                    .padding(.top, 6)
                statRow
                    .padding(.top, 7)
                badgesHeader
                    .padding(.top, 8)
                badgeGrid
                    .padding(.top, 4)
                featuredBadgeCard
                    .padding(.top, 5)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private var header: some View {
        HStack {
            Text("Den")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(PandaColor.white)
            Spacer()
            Button(action: onClose) {
                ZStack {
                    Circle().fill(PandaColor.white.opacity(0.18))
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(PandaColor.white)
                }
                .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
    }

    private var levelSection: some View {
        HStack(spacing: 10) {
            LevelRing(level: playerData.playerLevel, fraction: xpFraction)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(playerData.xpInCurrentLevel) / \(playerData.xpNeededForNextLevel) XP TO LV \(playerData.playerLevel + 1)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(PandaColor.white.opacity(0.5))

                Capsule()
                    .fill(PandaColor.white.opacity(0.1))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule()
                                .fill(PandaColor.green)
                                .frame(width: geo.size.width * xpFraction)
                        }
                    }

                if let nextUnlock {
                    Text("\(nextUnlock.name.uppercased()) UNLOCKS AT \(nextUnlock.level)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(PandaColor.white.opacity(0.4))
                        .lineLimit(1)
                } else {
                    Text("EVERYTHING UNLOCKED")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(PandaColor.greenMint.opacity(0.7))
                }
            }
        }
    }

    private var xpFraction: Double {
        guard playerData.xpNeededForNextLevel > 0 else { return 0 }
        return min(1, Double(playerData.xpInCurrentLevel) / Double(playerData.xpNeededForNextLevel))
    }

    private var statRow: some View {
        HStack(spacing: 4) {
            StatPill(value: "\(highScore)", label: "BEST")
            StatPill(value: "\(streak)", label: "STREAK", tint: streak > 0 ? PandaColor.green : PandaColor.white)
            StatPill(value: "\(playerData.gamesPlayed)", label: "RUNS")
        }
    }

    private var badgesHeader: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Badges")
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundColor(PandaColor.white)
            Spacer()
            Text("\(unlockedBadges.count) / \(Badge.all.count)")
                .font(.system(size: 7.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.4))
        }
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
            ForEach(Badge.all) { badge in
                BadgeTile(badge: badge, isUnlocked: badge.isUnlocked(playerData, highScore, streak))
                    .onTapGesture { selectedBadge = badge }
            }
        }
    }

    private var featuredBadgeCard: some View {
        let isUnlocked = featuredBadge.isUnlocked(playerData, highScore, streak)
        return VStack(alignment: .leading, spacing: 1) {
            Text(featuredBadge.name)
                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                .foregroundColor(isUnlocked ? featuredBadge.tint : PandaColor.white.opacity(0.5))
            Text(featuredBadge.description)
                .font(.system(size: 7.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.45))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PandaColor.inkRaised)
        .cornerRadius(8)
    }
}

// MARK: - Level ring

private struct LevelRing: View {
    let level: Int
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(PandaColor.white.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: max(0.02, fraction))
                .stroke(PandaColor.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(level)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(PandaColor.white)
                Text("LEVEL")
                    .font(.system(size: 6, design: .monospaced))
                    .tracking(0.6)
                    .foregroundColor(PandaColor.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Stat pill

private struct StatPill: View {
    let value: String
    let label: String
    var tint: Color = PandaColor.white

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 6.5, design: .monospaced))
                .tracking(0.6)
                .foregroundColor(PandaColor.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(PandaColor.inkRaised)
        .cornerRadius(8)
    }
}

// MARK: - Badge tile

private struct BadgeTile: View {
    let badge: Badge
    let isUnlocked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(isUnlocked ? badge.tint.opacity(0.16) : PandaColor.inkRaised)

            if isUnlocked {
                badgeShape
                    .fill(badge.tint)
                    .frame(width: 9, height: 9)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(PandaColor.white.opacity(0.3))
            }
        }
        .frame(height: 26)
    }

    private var badgeShape: AnyShape {
        switch badge.icon {
        case .diamond: AnyShape(DiamondShape())
        case .circle: AnyShape(Circle())
        case .triangle: AnyShape(TriangleShape())
        case .square: AnyShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
