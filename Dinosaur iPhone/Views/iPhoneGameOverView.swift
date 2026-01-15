import SwiftUI

struct iPhoneGameOverView: View {
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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onProfile) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20))
                            Text("Lv\(playerLevel)")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onHome) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onShop) {
                        HStack(spacing: 6) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 18))
                            Text("\(coins)")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Main content
                VStack(spacing: 20) {
                    Text("GAME OVER")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.red)

                    Text("\(score)")
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    if isNewHighScore {
                        Text("NEW HIGH SCORE!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                    } else {
                        Text("Best: \(highScore)")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }

                    // Rewards earned
                    if let reward = reward {
                        HStack(spacing: 30) {
                            HStack(spacing: 6) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 24))
                                Text("+\(reward.totalCoins)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.yellow)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 24))
                                Text("+\(reward.totalXP)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }

                        if reward.isFirstGameOfDay {
                            Text("Daily Bonus!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 20))
                        Text("\(streak) day streak")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Retry button
                if canRestart {
                    Button(action: onRestart) {
                        Text("TAP TO RETRY")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.green)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                    .transition(.opacity)
                } else {
                    Color.clear
                        .frame(height: 76)
                }

                Spacer()
                    .frame(height: 40)
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
