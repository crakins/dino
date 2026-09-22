import SwiftUI
import WatchKit

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let isNewHighScore: Bool
    let streak: Int
    let season: Season
    let runDurationSeconds: Int
    let reward: GameReward?
    let onRestart: () -> Void
    let onShop: () -> Void
    let onHome: () -> Void

    @State private var canRestart = false

    var body: some View {
        ZStack {
            // Only the background bleeds into the unsafe/rounded-corner region — buttons must
            // stay inset or they land in the bezel's touch dead-zone.
            PandaColor.ink.ignoresSafeArea()
            content
        }
    }

    private var content: some View {
        ScrollView {
            innerContent
        }
        .padding(.top, -30)
        .onAppear {
            canRestart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeIn(duration: 0.2)) {
                    canRestart = true
                }
            }
        }
    }

    private var innerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RUN ENDED")
                    .font(.numeral(size: 8))
                    .tracking(1.3)
                    .foregroundColor(PandaColor.white.opacity(0.4))
                Spacer()
                Text("\(season.displayName) · \(runDurationSeconds)s")
                    .font(.numeral(size: 8))
                    .tracking(0.8)
                    .foregroundColor(PandaColor.white.opacity(0.4))
            }

            HStack(alignment: .bottom, spacing: 6) {
                Text("\(score)")
                    .font(.numeral(size: 44, weight: .medium))
                    .tracking(-1)
                    .foregroundColor(PandaColor.white)

                VStack(alignment: .leading, spacing: 2) {
                    if isNewHighScore {
                        Text("NEW BEST")
                            .font(.heading(size: 7.5, weight: .heavy))
                            .tracking(0.6)
                            .foregroundColor(PandaColor.ink)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(PandaColor.greenMint)
                            .cornerRadius(5)
                        Text("WAS \(highScore)")
                            .font(.numeral(size: 7.5))
                            .foregroundColor(PandaColor.white.opacity(0.42))
                    } else {
                        Text("BEST \(highScore)")
                            .font(.numeral(size: 7.5))
                            .foregroundColor(PandaColor.white.opacity(0.42))
                    }
                }
                .padding(.bottom, 3)
            }
            .padding(.top, 5)

            if let reward {
                VStack(spacing: 3) {
                    ForEach(reward.lines) { line in
                        RewardRow(line: line)
                    }
                }
                .padding(.top, 8)
            }

            Text(streakConsequenceText)
                .font(.numeral(size: 7.5))
                .foregroundColor(PandaColor.white.opacity(0.42))
                .lineSpacing(1.5)
                .padding(.top, 8)
                .padding(.bottom, 5)

            HStack(spacing: 5) {
                Button(action: onRestart) {
                    Text("Retry")
                        .font(.heading(size: 11, weight: .heavy))
                        .tracking(0.3)
                        .foregroundColor(PandaColor.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(PandaColor.green)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(!canRestart)
                .opacity(canRestart ? 1 : 0.5)

                iconButton(systemName: "house.fill", action: onHome)
                iconButton(systemName: "cart.fill", action: onShop)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    private var streakConsequenceText: String {
        if streak <= 0 {
            return "Run again tomorrow to start a streak."
        } else {
            return "Run tomorrow to keep your \(streak)-day streak going."
        }
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12))
                .foregroundColor(PandaColor.white.opacity(0.75))
                .frame(width: 34, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(PandaColor.white.opacity(0.2), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RewardRow: View {
    let line: RewardLine

    var body: some View {
        HStack {
            Text(line.label)
                .font(.numeral(size: 8.5))
                .foregroundColor(line.isHighlight ? PandaColor.green : PandaColor.white.opacity(0.65))
            Spacer()
            Text("+\(line.amount)")
                .font(.numeral(size: 9.5, weight: .medium))
                .foregroundColor(line.isHighlight ? PandaColor.green : PandaColor.greenMint)
        }
        .padding(.horizontal, 7)
        .frame(height: 17)
        .background(line.isHighlight ? PandaColor.green.opacity(0.12) : PandaColor.inkRaised)
        .cornerRadius(6)
    }
}
