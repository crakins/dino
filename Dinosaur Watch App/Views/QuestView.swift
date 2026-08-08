import SwiftUI
import WatchKit

/// A local "ghost rival" — this game has no backend, so the burrow leaderboard is derived
/// deterministically from the player's own high score rather than pretending to be live data.
private struct Rival {
    let name: String
    let score: Int
}

struct QuestView: View {
    let playerData: PlayerData
    let highScore: Int
    let onClose: () -> Void
    let onRun: () -> Void

    private var progress: Int { playerData.todaysQuestProgress }
    private var target: Int { PlayerData.dailyQuestTarget }
    private var isComplete: Bool { playerData.isDailyQuestComplete }

    private var rivalAhead: Rival {
        // Deterministic offset so the gap feels alive day to day without needing a backend.
        let daySeed = Calendar.current.component(.dayOfYear, from: Date())
        let offset = 80 + (daySeed % 70)
        return Rival(name: "Mara", score: highScore + offset)
    }

    private var rivalBehind: Rival {
        let daySeed = Calendar.current.component(.dayOfYear, from: Date())
        let offset = 15 + (daySeed % 45)
        return Rival(name: "Ollie", score: max(0, highScore - offset))
    }

    private var resetCaption: String {
        let calendar = Calendar.current
        let midnight = calendar.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? Date()
        let hours = max(1, Int(midnight.timeIntervalSinceNow / 3600))
        return "RESETS IN \(hours)H"
    }

    var body: some View {
        ZStack {
            // Only the background bleeds into the unsafe/rounded-corner region — content must
            // stay inset or it lands in the bezel's touch dead-zone.
            PandaColor.ink.ignoresSafeArea()
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                questCard
                    .padding(.top, 6)
                Text("This week's burrow")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(PandaColor.white)
                    .padding(.top, 8)
                leaderboard
                    .padding(.top, 4)
                gapCaption
                    .padding(.top, 6)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private var header: some View {
        HStack {
            Text("Today")
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

            Text(resetCaption)
                .font(.system(size: 7.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.4))
                .padding(.leading, 4)
        }
    }

    private var questCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isComplete ? "Quest complete" : "Finish three runs")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(PandaColor.white)

            Text(isComplete ? "COME BACK TOMORROW FOR A NEW ONE" : "ANY RUN COUNTS · \(progress) OF \(target)")
                .font(.system(size: 7.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.5))
                .padding(.top, 2)

            HStack(spacing: 3) {
                ForEach(0..<target, id: \.self) { i in
                    Capsule()
                        .fill(i < progress ? PandaColor.green : PandaColor.white.opacity(0.12))
                        .frame(height: 4)
                }
            }
            .padding(.top, 6)

            HStack {
                Text("+\(PlayerData.dailyQuestXPReward) XP · +\(PlayerData.dailyQuestCoinReward)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(PandaColor.green)

                Spacer()

                if !isComplete {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        onRun()
                    } label: {
                        Text("Run →")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(PandaColor.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
        .padding(8)
        .background(
            LinearGradient(
                colors: [PandaColor.green.opacity(0.16), PandaColor.inkRaised],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(10)
    }

    private var leaderboard: some View {
        VStack(spacing: 3) {
            leaderboardRow(rank: 1, name: rivalAhead.name, score: rivalAhead.score, isYou: false)
            leaderboardRow(rank: 2, name: "You", score: highScore, isYou: true)
            leaderboardRow(rank: 3, name: rivalBehind.name, score: rivalBehind.score, isYou: false)
        }
    }

    private func leaderboardRow(rank: Int, name: String, score: Int, isYou: Bool) -> some View {
        HStack(spacing: 6) {
            Text("\(rank)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(isYou ? PandaColor.green : PandaColor.white.opacity(0.4))
                .frame(width: 9, alignment: .leading)
            Text(name)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(isYou ? PandaColor.green : PandaColor.white)
            Spacer()
            Text("\(score)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(isYou ? PandaColor.green : PandaColor.white)
        }
        .padding(.horizontal, 7)
        .frame(height: 20)
        .background(
            isYou
                ? AnyShapeStyle(PandaColor.green.opacity(0.16))
                : AnyShapeStyle(PandaColor.inkRaised)
        )
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isYou ? PandaColor.green.opacity(0.5) : Color.clear, lineWidth: 0.5)
        )
    }

    private var gapCaption: some View {
        let gap = rivalAhead.score - highScore
        return Text(gap > 0 ? "\(gap) more and \(rivalAhead.name)'s yours." : "You're in the lead.")
            .font(.system(size: 7.5, design: .monospaced))
            .foregroundColor(PandaColor.white.opacity(0.42))
    }
}
