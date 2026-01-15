import SwiftUI

struct ShopView: View {
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

    // Get currently equipped skins
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
        VStack(spacing: 2) {
            // Header with title
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 10))
                    Text("Marketplace")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 10))
                    Text("\(playerDataManager.playerData.coins)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.yellow)

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)

            // Category tabs - full width
            HStack(spacing: 2) {
                ForEach(ShopCategory.allCases, id: \.self) { cat in
                    Button(action: {
                        selectedCategory = cat
                        clearSelections()
                    }) {
                        Text(cat.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(selectedCategory == cat ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            // Content - no scroll
            switch selectedCategory {
            case .dinosaur:
                dinosaurShopContent
            case .obstacle:
                obstacleShopContent
            case .background:
                backgroundShopContent
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            selectedDinoSkin = equippedDinoSkin
            selectedObstacleSkin = equippedObstacleSkin
            selectedBackgroundSkin = equippedBackgroundSkin
        }
    }

    private func clearSelections() {
        switch selectedCategory {
        case .dinosaur:
            selectedDinoSkin = equippedDinoSkin
        case .obstacle:
            selectedObstacleSkin = equippedObstacleSkin
        case .background:
            selectedBackgroundSkin = equippedBackgroundSkin
        }
    }

    // MARK: - Dinosaur Shop

    private var dinosaurShopContent: some View {
        VStack(spacing: 4) {
            // Evolution chain - compact
            HStack(spacing: 2) {
                ForEach(DinosaurSkin.allCases) { skin in
                    smallSkinButton(for: skin)
                }
            }
            .padding(.horizontal, 4)

            // Selected skin detail
            if let skin = selectedDinoSkin {
                skinDetailView(for: skin)
            }
        }
    }

    private func smallSkinButton(for skin: DinosaurSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedDinosaurSkin == skin.rawValue
        let isSelected = selectedDinoSkin == skin
        let canPurchase = playerDataManager.playerData.canPurchase(skin)

        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 30, height: 34)

            DinosaurPreview(skin: skin, size: 18)

            if !isOwned && !canPurchase {
                Color.black.opacity(0.6)
                    .frame(width: 30, height: 34)
                    .cornerRadius(4)
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }

            if isEquipped {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .offset(x: 11, y: -13)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedDinoSkin = skin
        }
    }

    private func skinDetailView(for skin: DinosaurSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedDinosaurSkin == skin.rawValue
        let canPurchase = playerDataManager.playerData.canPurchase(skin)
        let hasLevel = playerDataManager.playerData.playerLevel >= skin.requiredPlayerLevel
        let hasPrevious = skin.previousSkin.map { playerDataManager.playerData.owns($0) } ?? true

        return HStack(spacing: 4) {
            // Skin name
            Text(skin.displayName)
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            // Fixed-width action area
            HStack(spacing: 2) {
                if !isOwned {
                    if !hasLevel {
                        HStack(spacing: 1) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                            Text("\(skin.requiredPlayerLevel)")
                                .font(.system(size: 7))
                        }
                        .foregroundColor(.red)
                    }
                    if !hasPrevious && skin.evolutionLevel > 1 {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.red)
                    }
                }

                Button(action: {
                    if isOwned && !isEquipped {
                        playerDataManager.equip(skin)
                    } else if !isOwned {
                        _ = playerDataManager.purchase(skin)
                    }
                }) {
                    Group {
                        if isEquipped {
                            Text("EQUIPPED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.green)
                        } else if isOwned {
                            Text("Equip")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            HStack(spacing: 1) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 8))
                                Text("\(skin.coinCost)")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(canPurchase ? .white : .gray)
                        }
                    }
                    .frame(width: 52, height: 18)
                    .background(isEquipped ? Color.clear : (isOwned ? Color.blue : (canPurchase ? Color.green : Color.gray.opacity(0.5))))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isEquipped || (!isOwned && !canPurchase))
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(6)
        .frame(height: 32)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
        .padding(.horizontal, 4)
    }

    // MARK: - Obstacle Shop

    private var obstacleShopContent: some View {
        VStack(spacing: 4) {
            // Evolution chain - compact
            HStack(spacing: 2) {
                ForEach(ObstacleSkin.allCases) { skin in
                    smallObstacleSkinButton(for: skin)
                }
            }
            .padding(.horizontal, 4)

            // Selected skin detail
            if let skin = selectedObstacleSkin {
                obstacleDetailView(for: skin)
            }
        }
    }

    private func smallObstacleSkinButton(for skin: ObstacleSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedObstacleSkin == skin.rawValue
        let isSelected = selectedObstacleSkin == skin
        let canPurchase = playerDataManager.playerData.canPurchase(skin)

        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 30, height: 34)

            ObstaclePreview(skin: skin, size: 22)

            if !isOwned && !canPurchase {
                Color.black.opacity(0.6)
                    .frame(width: 30, height: 34)
                    .cornerRadius(4)
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }

            if isEquipped {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .offset(x: 11, y: -13)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedObstacleSkin = skin
        }
    }

    private func obstacleDetailView(for skin: ObstacleSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedObstacleSkin == skin.rawValue
        let canPurchase = playerDataManager.playerData.canPurchase(skin)
        let hasLevel = playerDataManager.playerData.playerLevel >= skin.requiredPlayerLevel
        let hasPrevious = skin.previousSkin.map { playerDataManager.playerData.owns($0) } ?? true

        return HStack(spacing: 4) {
            Text(skin.displayName)
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            // Fixed-width action area
            HStack(spacing: 2) {
                if !isOwned {
                    if !hasLevel {
                        HStack(spacing: 1) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                            Text("\(skin.requiredPlayerLevel)")
                                .font(.system(size: 7))
                        }
                        .foregroundColor(.red)
                    }
                    if !hasPrevious && skin.evolutionLevel > 1 {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.red)
                    }
                }

                Button(action: {
                    if isOwned && !isEquipped {
                        playerDataManager.equip(skin)
                    } else if !isOwned {
                        _ = playerDataManager.purchase(skin)
                    }
                }) {
                    Group {
                        if isEquipped {
                            Text("EQUIPPED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.green)
                        } else if isOwned {
                            Text("Equip")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            HStack(spacing: 1) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 8))
                                Text("\(skin.coinCost)")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(canPurchase ? .white : .gray)
                        }
                    }
                    .frame(width: 52, height: 18)
                    .background(isEquipped ? Color.clear : (isOwned ? Color.blue : (canPurchase ? Color.green : Color.gray.opacity(0.5))))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isEquipped || (!isOwned && !canPurchase))
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(6)
        .frame(height: 32)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
        .padding(.horizontal, 4)
    }

    // MARK: - Background Shop

    private var backgroundShopContent: some View {
        VStack(spacing: 4) {
            // Evolution chain - compact
            HStack(spacing: 2) {
                ForEach(BackgroundSkin.allCases) { skin in
                    smallBackgroundSkinButton(for: skin)
                }
            }
            .padding(.horizontal, 4)

            // Selected skin detail
            if let skin = selectedBackgroundSkin {
                backgroundDetailView(for: skin)
            }
        }
    }

    private func smallBackgroundSkinButton(for skin: BackgroundSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedBackgroundSkin == skin.rawValue
        let isSelected = selectedBackgroundSkin == skin
        let canPurchase = playerDataManager.playerData.canPurchase(skin)

        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 30, height: 34)

            BackgroundPreview(skin: skin, size: 20)

            if !isOwned && !canPurchase {
                Color.black.opacity(0.6)
                    .frame(width: 30, height: 34)
                    .cornerRadius(4)
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }

            if isEquipped {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .offset(x: 11, y: -13)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedBackgroundSkin = skin
        }
    }

    private func backgroundDetailView(for skin: BackgroundSkin) -> some View {
        let isOwned = playerDataManager.playerData.owns(skin)
        let isEquipped = playerDataManager.playerData.equippedBackgroundSkin == skin.rawValue
        let canPurchase = playerDataManager.playerData.canPurchase(skin)
        let hasLevel = playerDataManager.playerData.playerLevel >= skin.requiredPlayerLevel
        let hasPrevious = skin.previousSkin.map { playerDataManager.playerData.owns($0) } ?? true

        return HStack(spacing: 4) {
            Text(skin.displayName)
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            // Fixed-width action area
            HStack(spacing: 2) {
                if !isOwned {
                    if !hasLevel {
                        HStack(spacing: 1) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                            Text("\(skin.requiredPlayerLevel)")
                                .font(.system(size: 7))
                        }
                        .foregroundColor(.red)
                    }
                    if !hasPrevious && skin.evolutionLevel > 1 {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.red)
                    }
                }

                Button(action: {
                    if isOwned && !isEquipped {
                        playerDataManager.equip(skin)
                    } else if !isOwned {
                        _ = playerDataManager.purchase(skin)
                    }
                }) {
                    Group {
                        if isEquipped {
                            Text("EQUIPPED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.green)
                        } else if isOwned {
                            Text("Equip")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            HStack(spacing: 1) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 8))
                                Text("\(skin.coinCost)")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(canPurchase ? .white : .gray)
                        }
                    }
                    .frame(width: 52, height: 18)
                    .background(isEquipped ? Color.clear : (isOwned ? Color.blue : (canPurchase ? Color.green : Color.gray.opacity(0.5))))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isEquipped || (!isOwned && !canPurchase))
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(6)
        .frame(height: 32)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
        .padding(.horizontal, 4)
    }

    // MARK: - Helper Views

    private func requirementRow(icon: String, text: String, isMet: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isMet ? "checkmark.circle.fill" : icon)
                .foregroundColor(isMet ? .green : .gray)
            Text(text)
                .foregroundColor(isMet ? .white : .gray)
        }
    }
}
