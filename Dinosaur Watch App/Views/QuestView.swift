import SwiftUI
import WatchKit

struct QuestView: View {
    let playerData: PlayerData
    let onClose: () -> Void
    let onRun: () -> Void

    private var progress: Int { playerData.todaysQuestProgress }
    private var target: Int { PlayerData.dailyQuestTarget }
    private var isComplete: Bool { playerData.isDailyQuestComplete }

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
            }
            .padding(.horizontal, 8)
            .padding(.top, -30)
            .padding(.bottom, 8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            MarketBackButton(label: "Home", action: onClose)

            HStack {
                Text("Today")
                    .font(.heading(size: 12, weight: .heavy))
                    .foregroundColor(PandaColor.white)
                Spacer()
                HStack(spacing: 3) {
                    CoinDot(size: 9)
                    Text("\(playerData.coins)")
                        .font(.numeral(size: 10, weight: .medium))
                        .foregroundColor(PandaColor.greenMint)
                }
            }
            .padding(.top, 2)

            Text(resetCaption)
                .font(.numeral(size: 7.5))
                .foregroundColor(PandaColor.white.opacity(0.4))
        }
    }

    private var questCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isComplete ? "Quest complete" : "Finish three runs")
                .font(.heading(size: 11, weight: .semibold))
                .foregroundColor(PandaColor.white)

            Text(isComplete ? "COME BACK TOMORROW FOR A NEW ONE" : "ANY RUN COUNTS · \(progress) OF \(target)")
                .font(.numeral(size: 7.5))
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
                    .font(.numeral(size: 8, weight: .medium))
                    .foregroundColor(PandaColor.green)

                Spacer()

                if !isComplete {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        onRun()
                    } label: {
                        Text("Run →")
                            .font(.heading(size: 8.5, weight: .semibold))
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
}
