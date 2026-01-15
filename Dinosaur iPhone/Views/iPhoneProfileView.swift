import SwiftUI

struct iPhoneProfileView: View {
    var playerDataManager: PlayerDataManager
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Level display
                        VStack(spacing: 8) {
                            Text("Level \(playerDataManager.playerData.playerLevel)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.blue)

                            // XP Progress bar
                            VStack(spacing: 4) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 16)

                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue)
                                            .frame(width: geometry.size.width * xpProgress, height: 16)
                                    }
                                }
                                .frame(height: 16)

                                HStack {
                                    Text("\(playerDataManager.playerData.xpInCurrentLevel) XP")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(playerDataManager.playerData.xpNeededForNextLevel) XP to next level")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            statCard(
                                icon: "dollarsign.circle.fill",
                                iconColor: .yellow,
                                title: "Coins",
                                value: "\(playerDataManager.playerData.coins)"
                            )

                            statCard(
                                icon: "star.fill",
                                iconColor: .blue,
                                title: "Total XP",
                                value: "\(playerDataManager.playerData.totalXP)"
                            )

                            statCard(
                                icon: "gamecontroller.fill",
                                iconColor: .green,
                                title: "Games Played",
                                value: "\(playerDataManager.playerData.gamesPlayed)"
                            )

                            statCard(
                                icon: "trophy.fill",
                                iconColor: .orange,
                                title: "Skins Owned",
                                value: "\(totalSkinsOwned)"
                            )
                        }
                        .padding(.horizontal)

                        // Equipped skins section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipped")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            HStack(spacing: 16) {
                                equippedSkinCard(
                                    title: "Dino",
                                    preview: AnyView(DinosaurPreview(skin: equippedDino, size: 40))
                                )

                                equippedSkinCard(
                                    title: "Hazard",
                                    preview: AnyView(ObstaclePreview(skin: equippedObstacle, size: 40))
                                )

                                equippedSkinCard(
                                    title: "World",
                                    preview: AnyView(BackgroundPreview(skin: equippedBackground, size: 30))
                                )
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
    }

    private var xpProgress: CGFloat {
        let needed = playerDataManager.playerData.xpNeededForNextLevel
        let current = playerDataManager.playerData.xpInCurrentLevel
        guard needed > 0 else { return 1.0 }
        return CGFloat(current) / CGFloat(needed + current)
    }

    private var totalSkinsOwned: Int {
        playerDataManager.playerData.ownedDinosaurSkins.count +
        playerDataManager.playerData.ownedObstacleSkins.count +
        playerDataManager.playerData.ownedBackgroundSkins.count
    }

    private var equippedDino: DinosaurSkin {
        DinosaurSkin(rawValue: playerDataManager.playerData.equippedDinosaurSkin) ?? .squaresaurus
    }

    private var equippedObstacle: ObstacleSkin {
        ObstacleSkin(rawValue: playerDataManager.playerData.equippedObstacleSkin) ?? .cactus
    }

    private var equippedBackground: BackgroundSkin {
        BackgroundSkin(rawValue: playerDataManager.playerData.equippedBackgroundSkin) ?? .desertNight
    }

    private func statCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }

    private func equippedSkinCard(title: String, preview: AnyView) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 80)

                preview
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
