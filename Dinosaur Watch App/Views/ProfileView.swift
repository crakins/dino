import SwiftUI

struct ProfileView: View {
    let playerData: PlayerData
    let highScore: Int
    let streak: Int
    let onClose: () -> Void

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
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                levelSection
                    .padding(.top, 6)
                statRow
                    .padding(.top, 7)
            }
            .padding(.horizontal, 8)
            .padding(.top, -30)
            .padding(.bottom, 8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            MarketBackButton(label: "Home", action: onClose)

            Text("Profile")
                .font(.heading(size: 12, weight: .heavy))
                .foregroundColor(PandaColor.white)
                .padding(.top, 2)
        }
    }

    private var levelSection: some View {
        HStack(spacing: 10) {
            LevelRing(level: playerData.playerLevel, fraction: xpFraction)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(playerData.xpInCurrentLevel) / \(playerData.xpNeededForNextLevel) XP TO LV \(playerData.playerLevel + 1)")
                    .font(.numeral(size: 8))
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
                        .font(.numeral(size: 8))
                        .foregroundColor(PandaColor.white.opacity(0.4))
                        .lineLimit(1)
                } else {
                    Text("EVERYTHING UNLOCKED")
                        .font(.numeral(size: 8))
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
                    .font(.heading(size: 19, weight: .heavy))
                    .foregroundColor(PandaColor.white)
                Text("LEVEL")
                    .font(.numeral(size: 6))
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
                .font(.numeral(size: 12, weight: .medium))
                .foregroundColor(tint)
            Text(label)
                .font(.numeral(size: 6.5))
                .tracking(0.6)
                .foregroundColor(PandaColor.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(PandaColor.inkRaised)
        .cornerRadius(8)
    }
}
