import SwiftUI

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let isNewHighScore: Bool
    let streak: Int
    let reward: GameReward?
    let playerLevel: Int
    let coins: Int
    let onRestart: () -> Void
    let onShop: () -> Void
    let onProfile: () -> Void
    let onHome: () -> Void

    @State private var canRestart = false

    var body: some View {
        VStack(spacing: 4) {
            // Header bar - consistent with MenuView
            HStack {
                Button(action: onProfile) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 12))
                        Text("Lv\(playerLevel)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(5)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onShop) {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 12))
                        Text("\(coins)")
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // Score display
            Text("GAME OVER")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.red)

            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            if isNewHighScore {
                Text("NEW HIGH SCORE!")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Text("Best: \(highScore)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Rewards earned
            if let reward = reward {
                HStack(spacing: 12) {
                    HStack(spacing: 2) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                        Text("+\(reward.totalCoins)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 10))
                        Text("+\(reward.totalXP)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }

                if reward.isFirstGameOfDay {
                    Text("Daily Bonus!")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.green)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 10))
                Text("\(streak) day streak")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }

            Spacer()

            if canRestart {
                Text("Tap to Retry")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .transition(.opacity)
            } else {
                Text(" ")
                    .font(.system(size: 11))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .contentShape(Rectangle())
        .onTapGesture {
            if canRestart {
                onRestart()
            }
        }
        .onAppear {
            canRestart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    canRestart = true
                }
            }
        }
    }
}
