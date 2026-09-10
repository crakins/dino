import SwiftUI
import WatchKit

// MARK: - Kin detail

struct KinDetailView: View {
    let kin: Kin
    var playerDataManager: PlayerDataManager
    let onBack: () -> Void
    var onPlay: (() -> Void)? = nil

    var body: some View {
        let data = playerDataManager.playerData
        let isOwned = data.owns(kin)
        let isEquipped = data.equippedKin == kin.rawValue
        let hasLevel = data.playerLevel >= kin.requiredPlayerLevel
        let hasWorld = kin.requiredWorld.map { data.owns($0) } ?? true
        let canPurchase = data.canPurchase(kin)

        ZStack {
            // Only the background bleeds into the unsafe/rounded-corner region — the back
            // button must stay inset or it lands in the bezel's touch dead-zone.
            PandaColor.ink.ignoresSafeArea()
            kinDetailContent(data: data, isOwned: isOwned, isEquipped: isEquipped, hasLevel: hasLevel, hasWorld: hasWorld, canPurchase: canPurchase)
        }
    }

    private func kinDetailContent(data: PlayerData, isOwned: Bool, isEquipped: Bool, hasLevel: Bool, hasWorld: Bool, canPurchase: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MarketBackButton(label: "Market", action: onBack)
            Text("KIN · \(kin.stage) OF \(Kin.allCases.count)")
                .font(.numeral(size: 8))
                .tracking(0.9)
                .foregroundColor(PandaColor.white.opacity(0.4))
                .padding(.top, 2)

            ZStack {
                RadialGradient(colors: [kin.earAccent.opacity(0.16), PandaColor.inkRaised], center: .init(x: 0.5, y: 0.6), startRadius: 0, endRadius: 90)

                GeometryReader { geo in
                    Canvas { context, size in
                        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height).insetBy(dx: size.width * 0.3, dy: size.height * 0.16)
                        PandaGraphics.drawHeadMark(&context, in: rect.offsetBy(dx: 0, dy: -6), earColor: kin.earAccent, accessory: kin.accessory, expression: kin.expression)
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
                .font(.heading(size: 16, weight: .heavy))
                .foregroundColor(PandaColor.white)
                .padding(.top, 7)

            Text(kin.tagline)
                .font(.numeral(size: 8.5))
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

            HStack(spacing: 6) {
                MarketActionButton(
                    isOwned: isOwned,
                    isEquipped: isEquipped,
                    canPurchase: canPurchase,
                    cost: kin.coinCost,
                    coins: data.coins,
                    hasLevel: hasLevel,
                    requiredLevel: kin.requiredPlayerLevel,
                    hasRequiredWorld: hasWorld,
                    requiredWorldName: kin.requiredWorld?.shortName ?? "",
                    onEquip: { playerDataManager.equip(kin) },
                    onPurchase: { _ = playerDataManager.purchase(kin) }
                )

                if isOwned, let onPlay {
                    Button(action: {
                        if !isEquipped { playerDataManager.equip(kin) }
                        onPlay()
                    }) {
                        Text("Play")
                            .font(.heading(size: 12, weight: .heavy))
                            .foregroundColor(PandaColor.ink)
                            .frame(width: 54)
                            .frame(height: 30)
                            .background(PandaColor.greenMint)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .font(.numeral(size: 7.5, weight: .medium))
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
    var onPlay: (() -> Void)? = nil

    var body: some View {
        let data = playerDataManager.playerData
        let isOwned = data.owns(world)
        let isEquipped = data.equippedWorld == world.rawValue
        let hasLevel = data.playerLevel >= world.requiredPlayerLevel
        let canPurchase = data.canPurchase(world)

        ZStack {
            // Only the background bleeds into the unsafe/rounded-corner region — the back
            // button must stay inset or it lands in the bezel's touch dead-zone.
            PandaColor.ink.ignoresSafeArea()
            worldDetailContent(data: data, isOwned: isOwned, isEquipped: isEquipped, hasLevel: hasLevel, canPurchase: canPurchase)
        }
    }

    private func worldDetailContent(data: PlayerData, isOwned: Bool, isEquipped: Bool, hasLevel: Bool, canPurchase: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MarketBackButton(label: "Market", action: onBack)
            Text("WORLDS")
                .font(.numeral(size: 8))
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
                .font(.heading(size: 16, weight: .heavy))
                .foregroundColor(PandaColor.white)
                .padding(.top, 7)

            Text("Every run through here dodges \(world.hazardName.lowercased()).")
                .font(.numeral(size: 8.5))
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

            HStack(spacing: 6) {
                MarketActionButton(
                    isOwned: isOwned,
                    isEquipped: isEquipped,
                    canPurchase: canPurchase,
                    cost: world.coinCost,
                    coins: data.coins,
                    hasLevel: hasLevel,
                    requiredLevel: world.requiredPlayerLevel,
                    onEquip: { playerDataManager.equip(world) },
                    onPurchase: { _ = playerDataManager.purchase(world) }
                )

                if isOwned, let onPlay {
                    Button(action: {
                        if !isEquipped { playerDataManager.equip(world) }
                        onPlay()
                    }) {
                        Text("Play")
                            .font(.heading(size: 12, weight: .heavy))
                            .foregroundColor(PandaColor.ink)
                            .frame(width: 54)
                            .frame(height: 30)
                            .background(PandaColor.greenMint)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tag(_ text: String, color: Color, background: Color) -> some View {
        Text(text)
            .font(.numeral(size: 7.5, weight: .medium))
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
    /// Whether the player's level meets this item's requirement — when it doesn't, the button
    /// tells them the level to reach instead of showing a purchase price they can't act on yet.
    var hasLevel: Bool = true
    var requiredLevel: Int = 1
    /// Kin only: some stages also require owning a specific World first. When that's the actual
    /// blocker (level and coins are otherwise fine), the button says so instead of just "Unlock".
    var hasRequiredWorld: Bool = true
    var requiredWorldName: String = ""
    let onEquip: () -> Void
    let onPurchase: () -> Void

    private var isBlocked: Bool { !hasLevel || !hasRequiredWorld }

    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                HStack(spacing: 4) {
                    if !isOwned && !isBlocked {
                        CoinDot(size: 11)
                    }
                    Text(buttonTitle)
                        .font(.heading(size: 11, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundColor(textColor)
                }
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(backgroundColor)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isEquipped || (!isOwned && !canPurchase))

            if !isOwned {
                Text(captionText)
                    .font(.numeral(size: 7.5))
                    .foregroundColor(PandaColor.white.opacity(0.38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var buttonTitle: String {
        if isEquipped { return "Equipped" }
        if isOwned { return "Equip" }
        if !hasLevel { return "Needs LV \(requiredLevel)" }
        if !hasRequiredWorld { return "Needs \(requiredWorldName)" }
        return "Unlock \(cost)"
    }

    private var captionText: String {
        if !hasLevel {
            return "REACH LEVEL \(requiredLevel) TO UNLOCK"
        }
        if !hasRequiredWorld {
            return "OWN \(requiredWorldName.uppercased()) TO UNLOCK"
        }
        let short = max(0, cost - coins)
        if short > 0 {
            return "\(short) MORE COINS NEEDED"
        }
        return "\(coins) IN POUCH · \(max(0, coins - cost)) AFTER"
    }

    private var backgroundColor: Color {
        if isEquipped { return PandaColor.inkRaised }
        if isOwned { return PandaColor.green }
        if isBlocked { return PandaColor.inkRaised }
        return canPurchase ? PandaColor.greenMint : PandaColor.inkRaised
    }

    /// The button's background is only ever bright (green/greenMint) when it's a live, actionable
    /// "Equip"/"Unlock" — every other state (equipped, blocked, unaffordable) sits on a dark
    /// `inkRaised` background, so the label needs to flip to light text or it reads as blank.
    private var textColor: Color {
        let brightBackground = (isOwned && !isEquipped) || (!isOwned && !isBlocked && canPurchase)
        return brightBackground ? PandaColor.ink : PandaColor.white.opacity(isEquipped ? 0.4 : 0.7)
    }

    private func action() {
        if isOwned {
            onEquip()
        } else {
            onPurchase()
        }
    }
}
