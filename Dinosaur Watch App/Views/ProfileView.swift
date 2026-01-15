import SwiftUI

struct ProfileView: View {
    let playerData: PlayerData
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Profile")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            // Level badge
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                VStack(spacing: 0) {
                    Text("\(playerData.playerLevel)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("LEVEL")
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // XP Progress bar
            VStack(spacing: 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: geo.size.width * progressPercent)
                    }
                }
                .frame(height: 8)

                Text("\(playerData.xpInCurrentLevel)/\(playerData.xpNeededForNextLevel) XP")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)

            // Stats grid
            HStack(spacing: 12) {
                StatBox(
                    value: "\(playerData.coins)",
                    label: "Coins",
                    icon: "dollarsign.circle.fill",
                    color: .yellow
                )
                StatBox(
                    value: "\(playerData.gamesPlayed)",
                    label: "Games",
                    icon: "gamecontroller.fill",
                    color: .green
                )
            }

            // Total XP
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 10))
                Text("Total XP: \(playerData.totalXP)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var progressPercent: CGFloat {
        guard playerData.xpNeededForNextLevel > 0 else { return 1.0 }
        return min(1.0, CGFloat(playerData.xpInCurrentLevel) / CGFloat(playerData.xpNeededForNextLevel))
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
    }
}
