import SwiftUI
import WatchKit

// MARK: - Kin detail

struct KinDetailView: View {
    let kin: Kin
    var playerDataManager: PlayerDataManager
    let onBack: () -> Void

    var body: some View {
        let data = playerDataManager.playerData
        let isOwned = data.owns(kin)
        let isEquipped = data.equippedKin == kin.rawValue
        let hasLevel = data.playerLevel >= kin.requiredPlayerLevel
        let hasWorld = kin.requiredWorld.map { data.owns($0) } ?? true
        let canPurchase = data.canPurchase(kin)

        VStack(alignment: .leading, spacing: 0) {
            MarketBackButton(label: "Market", action: onBack)
            Text("KIN · \(kin.stage) OF \(Kin.allCases.count)")
                .font(.system(size: 8, design: .monospaced))
                .tracking(0.9)
                .foregroundColor(PandaColor.white.opacity(0.4))
                .padding(.top, 2)

            ZStack {
                RadialGradient(colors: [kin.earAccent.opacity(0.16), PandaColor.inkRaised], center: .init(x: 0.5, y: 0.6), startRadius: 0, endRadius: 90)

                GeometryReader { geo in
                    Canvas { context, size in
                        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height).insetBy(dx: size.width * 0.3, dy: size.height * 0.16)
                        PandaGraphics.drawHeadMark(&context, in: rect.offsetBy(dx: 0, dy: -6), earColor: kin.earAccent)
                    }
                }

                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(Kin.allCases) { stage in
                            evolutionDot(for: stage, currentlyOwned: isOwned)
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
            .frame(height: 74)
            .cornerRadius(11)
            .padding(.top, 4)

            Text(kin.displayName)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(PandaColor.white)
                .padding(.top, 7)

            Text(kin.tagline)
                .font(.system(size: 8.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.5))
                .lineSpacing(1.5)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            HStack(spacing: 4) {
                if let perk = kin.perkTag {
                    tag(perk, color: PandaColor.greenMint, background: PandaColor.greenMint.opacity(0.14))
                }
                if !isOwned, let world = kin.requiredWorld, !hasWorld {
                    tag("NEEDS \(world.shortName.uppercased())", color: PandaColor.white.opacity(0.6), background: PandaColor.white.opacity(0.08))
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 4)

            MarketActionButton(
                isOwned: isOwned,
                isEquipped: isEquipped,
                canPurchase: canPurchase,
                cost: kin.coinCost,
                coins: data.coins,
                onEquip: { playerDataManager.equip(kin) },
                onPurchase: { _ = playerDataManager.purchase(kin) }
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PandaColor.ink)
        .ignoresSafeArea()
    }

    private func evolutionDot(for stage: Kin, currentlyOwned: Bool) -> some View {
        let owned = playerDataManager.playerData.owns(stage)
        let isCurrent = stage == kin

        return Group {
            if isCurrent {
                Circle().fill(PandaColor.greenMint)
            } else if owned {
                Circle().fill(PandaColor.white)
            } else {
                Circle().strokeBorder(PandaColor.white.opacity(0.35), lineWidth: 0.5)
            }
        }
        .frame(width: 5, height: 5)
    }

    private func tag(_ text: String, color: Color, background: Color) -> some View {
        Text(text)
            .font(.system(size: 7.5, weight: .medium, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background)
            .cornerRadius(6)
    }
}

// MARK: - World detail

struct WorldDetailView: View {
    let world: World
    var playerDataManager: PlayerDataManager
    let onBack: () -> Void

    var body: some View {
        let data = playerDataManager.playerData
        let isOwned = data.owns(world)
        let isEquipped = data.equippedWorld == world.rawValue
        let hasLevel = data.playerLevel >= world.requiredPlayerLevel
        let canPurchase = data.canPurchase(world)

        VStack(alignment: .leading, spacing: 0) {
            MarketBackButton(label: "Market", action: onBack)
            Text("WORLDS")
                .font(.system(size: 8, design: .monospaced))
                .tracking(0.9)
                .foregroundColor(PandaColor.white.opacity(0.4))
                .padding(.top, 2)

            ZStack {
                RadialGradient(colors: [world.accentColor.opacity(0.16), PandaColor.inkRaised], center: .init(x: 0.5, y: 0.6), startRadius: 0, endRadius: 90)
                WorldTileScene(world: world)
                    .scaleEffect(1.4)
                    .clipped()
            }
            .frame(height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .padding(.top, 4)

            Text(world.displayName)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(PandaColor.white)
                .padding(.top, 7)

            Text("Every run through here dodges \(world.hazardName.lowercased()).")
                .font(.system(size: 8.5, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.5))
                .lineSpacing(1.5)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            HStack(spacing: 4) {
                tag(world.hazardName, color: world.accentColor, background: world.accentColor.opacity(0.14))
                if !isOwned && !hasLevel {
                    tag("NEEDS LV \(world.requiredPlayerLevel)", color: PandaColor.white.opacity(0.6), background: PandaColor.white.opacity(0.08))
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 4)

            MarketActionButton(
                isOwned: isOwned,
                isEquipped: isEquipped,
                canPurchase: canPurchase,
                cost: world.coinCost,
                coins: data.coins,
                onEquip: { playerDataManager.equip(world) },
                onPurchase: { _ = playerDataManager.purchase(world) }
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PandaColor.ink)
        .ignoresSafeArea()
    }

    private func tag(_ text: String, color: Color, background: Color) -> some View {
        Text(text)
            .font(.system(size: 7.5, weight: .medium, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background)
            .cornerRadius(6)
    }
}

// MARK: - Shared action button

struct MarketActionButton: View {
    let isOwned: Bool
    let isEquipped: Bool
    let canPurchase: Bool
    let cost: Int
    let coins: Int
    let onEquip: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                HStack(spacing: 4) {
                    if !isOwned {
                        CoinDot(size: 11)
                    }
                    Text(buttonTitle)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(isEquipped ? PandaColor.white.opacity(0.4) : PandaColor.ink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(backgroundColor)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isEquipped || (!isOwned && !canPurchase))

            if !isOwned {
                Text("\(coins) IN POUCH · \(max(0, coins - cost)) AFTER")
                    .font(.system(size: 7.5, design: .monospaced))
                    .foregroundColor(PandaColor.white.opacity(0.38))
            }
        }
    }

    private var buttonTitle: String {
        if isEquipped { return "Equipped" }
        if isOwned { return "Equip" }
        return "Unlock \(cost)"
    }

    private var backgroundColor: Color {
        if isEquipped { return PandaColor.inkRaised }
        if isOwned { return PandaColor.green }
        return canPurchase ? PandaColor.greenMint : PandaColor.inkRaised
    }

    private func action() {
        if isOwned {
            onEquip()
        } else {
            onPurchase()
        }
    }
}
