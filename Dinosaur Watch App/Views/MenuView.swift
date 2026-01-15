import SwiftUI

struct MenuView: View {
    let highScore: Int
    let streak: Int
    let playerLevel: Int
    let coins: Int
    let onStart: () -> Void
    let onShop: () -> Void
    let onProfile: () -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 6) {
            // Header bar with Profile and Shop
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
                .disabled(isLoading)

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
                .disabled(isLoading)
            }
            .padding(.horizontal, 4)

            Spacer()

            // Main content - tappable area
            VStack(spacing: 8) {
                Text("DINO RUN")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.green)

                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text("Best: \(highScore)")
                            .font(.system(size: 12, weight: .medium))
                    }

                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("\(streak) day streak")
                            .font(.system(size: 12, weight: .medium))
                    }
                }

                Text(encouragementMessage)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(.green)
            } else {
                Text("Tap to Play")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isLoading else { return }
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onStart()
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
