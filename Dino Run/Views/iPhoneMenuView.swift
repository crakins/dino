import SwiftUI

struct iPhoneMenuView: View {
    let highScore: Int
    let streak: Int
    let playerLevel: Int
    let coins: Int
    let onStart: () -> Void
    let onShop: () -> Void
    let onProfile: () -> Void

    var body: some View {
        ZStack {
            // Background
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
                VStack(spacing: 24) {
                    // Title
                    Text("DINO RUN")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    // Dino preview
                    DinosaurPreview(skin: .squaresaurus, size: 80)
                        .frame(height: 100)

                    // Stats
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 20))
                            Text("Best: \(highScore)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 20))
                            Text("\(streak) day streak")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    // Encouragement
                    Text(encouragementMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Play button
                Button(action: onStart) {
                    Text("TAP TO PLAY")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.green)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private var encouragementMessage: String {
        if streak >= 7 {
            return "Incredible! A whole week!"
        } else if streak >= 3 {
            return "Keep that streak going!"
        } else if streak > 0 {
            return "Play daily to build your streak!"
        } else {
            return "Start your streak today!"
        }
    }
}
