import SwiftUI

struct iPhoneShopView: View {
    var playerDataManager: PlayerDataManager
    let onClose: () -> Void

    @State private var selectedCategory: ShopCategory = .dinosaur
    @State private var selectedDinoSkin: DinosaurSkin?
    @State private var selectedObstacleSkin: ObstacleSkin?
    @State private var selectedBackgroundSkin: BackgroundSkin?

    enum ShopCategory: String, CaseIterable {
        case dinosaur = "Dino"
        case obstacle = "Hazards"
        case background = "World"
    }

    private var equippedDinoSkin: DinosaurSkin {
        DinosaurSkin(rawValue: playerDataManager.playerData.equippedDinosaurSkin) ?? .squaresaurus
    }

    private var equippedObstacleSkin: ObstacleSkin {
        ObstacleSkin(rawValue: playerDataManager.playerData.equippedObstacleSkin) ?? .cactus
    }

    private var equippedBackgroundSkin: BackgroundSkin {
        BackgroundSkin(rawValue: playerDataManager.playerData.equippedBackgroundSkin) ?? .desertNight
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Coin balance
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 24))
                        Text("\(playerDataManager.playerData.coins)")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .foregroundColor(.yellow)
                    .padding(.top, 8)

                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ShopCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Content
                    ScrollView {
                        switch selectedCategory {
                        case .dinosaur:
                            dinosaurGrid
                        case .obstacle:
                            obstacleGrid
                        case .background:
                            backgroundGrid
                        }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
        .onAppear {
            selectedDinoSkin = equippedDinoSkin
            selectedObstacleSkin = equippedObstacleSkin
            selectedBackgroundSkin = equippedBackgroundSkin
        }
        .onChange(of: selectedCategory) { _, _ in
            // Reset selection to equipped when switching categories
            selectedDinoSkin = equippedDinoSkin
            selectedObstacleSkin = equippedObstacleSkin
            selectedBackgroundSkin = equippedBackgroundSkin
        }
    }

    // MARK: - Dinosaur Grid

    private var dinosaurGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(DinosaurSkin.allCases) { skin in
                skinCard(for: skin)
            }
        }
        .padding()
    }

    private func skinCard(for skin: DinosaurSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedDinosaurSkin == skin.rawValue
        let canPurchase = playerDataManager.playerData.canPurchase(skin)
        let isSelected = selectedDinoSkin == skin

        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 100)

                DinosaurPreview(skin: skin, size: 50)

                if !isOwned && !canPurchase {
                    Color.black.opacity(0.6)
                        .cornerRadius(12)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                if isEquipped {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
            )

            Text(skin.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            // Action button
            actionButton(
                isOwned: isOwned,
                isEquipped: isEquipped,
                canPurchase: canPurchase,
                cost: skin.coinCost,
                requiredLevel: skin.requiredPlayerLevel,
                onEquip: { playerDataManager.equip(skin) },
                onPurchase: { _ = playerDataManager.purchase(skin) }
            )
        }
        .onTapGesture {
            selectedDinoSkin = skin
        }
    }

    // MARK: - Obstacle Grid

    private var obstacleGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(ObstacleSkin.allCases) { skin in
                obstacleCard(for: skin)
            }
        }
        .padding()
    }

    private func obstacleCard(for skin: ObstacleSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedObstacleSkin == skin.rawValue
        let canPurchase = playerDataManager.playerData.canPurchase(skin)
        let isSelected = selectedObstacleSkin == skin

        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 100)

                ObstaclePreview(skin: skin, size: 50)

                if !isOwned && !canPurchase {
                    Color.black.opacity(0.6)
                        .cornerRadius(12)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                if isEquipped {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
            )

            Text(skin.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            actionButton(
                isOwned: isOwned,
                isEquipped: isEquipped,
                canPurchase: canPurchase,
                cost: skin.coinCost,
                requiredLevel: skin.requiredPlayerLevel,
                onEquip: { playerDataManager.equip(skin) },
                onPurchase: { _ = playerDataManager.purchase(skin) }
            )
        }
        .onTapGesture {
            selectedObstacleSkin = skin
        }
    }

    // MARK: - Background Grid

    private var backgroundGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(BackgroundSkin.allCases) { skin in
                backgroundCard(for: skin)
            }
        }
        .padding()
    }

    private func backgroundCard(for skin: BackgroundSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedBackgroundSkin == skin.rawValue
        let canPurchase = playerDataManager.playerData.canPurchase(skin)
        let isSelected = selectedBackgroundSkin == skin

        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 80)

                BackgroundPreview(skin: skin, size: 40)

                if !isOwned && !canPurchase {
                    Color.black.opacity(0.6)
                        .cornerRadius(12)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                if isEquipped {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
            )

            Text(skin.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            actionButton(
                isOwned: isOwned,
                isEquipped: isEquipped,
                canPurchase: canPurchase,
                cost: skin.coinCost,
                requiredLevel: skin.requiredPlayerLevel,
                onEquip: { playerDataManager.equip(skin) },
                onPurchase: { _ = playerDataManager.purchase(skin) }
            )
        }
        .onTapGesture {
            selectedBackgroundSkin = skin
        }
    }

    // MARK: - Action Button

    private func actionButton(
        isOwned: Bool,
        isEquipped: Bool,
        canPurchase: Bool,
        cost: Int,
        requiredLevel: Int,
        onEquip: @escaping () -> Void,
        onPurchase: @escaping () -> Void
    ) -> some View {
        Group {
            if isEquipped {
                Text("EQUIPPED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .frame(height: 28)
            } else if isOwned {
                Button(action: onEquip) {
                    Text("Equip")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onPurchase) {
                    HStack(spacing: 4) {
                        if playerDataManager.playerData.playerLevel < requiredLevel {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("\(requiredLevel)")
                                .font(.system(size: 10))
                        }
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                        Text("\(cost)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(canPurchase ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(canPurchase ? Color.green : Color.gray.opacity(0.3))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canPurchase)
            }
        }
    }
}
