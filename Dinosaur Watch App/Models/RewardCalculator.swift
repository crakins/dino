import Foundation

struct RewardLine: Identifiable {
    let id = UUID()
    let label: String
    let amount: Int
    let isHighlight: Bool
}

struct GameReward {
    let lines: [RewardLine]
    let totalCoins: Int
    let baseXP: Int
    let bonusXP: Int
    let isFirstGameOfDay: Bool
    let isNewHighScore: Bool

    var totalXP: Int { baseXP + bonusXP }
}

struct RewardCalculator {
    static func calculate(
        score: Int,
        shootsCollected: Int,
        streak: Int,
        isNewHighScore: Bool,
        lastDailyBonusDate: Double
    ) -> GameReward {
        let isFirstGameOfDay = !Calendar.current.isDateInToday(
            Date(timeIntervalSince1970: lastDailyBonusDate)
        )

        var lines: [RewardLine] = []
        var totalCoins = 0

        let distanceCoins = score / 10
        lines.append(RewardLine(label: "DISTANCE", amount: distanceCoins, isHighlight: false))
        totalCoins += distanceCoins

        if shootsCollected > 0 {
            let shootCoins = shootsCollected * 2
            lines.append(RewardLine(label: "SHOOTS ×\(shootsCollected)", amount: shootCoins, isHighlight: false))
            totalCoins += shootCoins
        }

        let streakPercent: Int
        if streak >= 14 { streakPercent = 30 }
        else if streak >= 7 { streakPercent = 20 }
        else if streak >= 3 { streakPercent = 10 }
        else { streakPercent = 0 }

        if streakPercent > 0 {
            let streakCoins = distanceCoins * streakPercent / 100
            let multiplier = 1 + Double(streakPercent) / 100
            lines.append(RewardLine(
                label: "\(streak)-DAY STREAK ×\(String(format: "%.1f", multiplier))",
                amount: streakCoins,
                isHighlight: false
            ))
            totalCoins += streakCoins
        }

        let milestoneCoins: Int
        if score >= 1000 { milestoneCoins = 50 }
        else if score >= 500 { milestoneCoins = 30 }
        else if score >= 200 { milestoneCoins = 15 }
        else if score >= 100 { milestoneCoins = 5 }
        else { milestoneCoins = 0 }

        if milestoneCoins > 0 {
            lines.append(RewardLine(label: "MILESTONE", amount: milestoneCoins, isHighlight: false))
            totalCoins += milestoneCoins
        }

        if isNewHighScore && distanceCoins > 0 {
            let bonus = max(1, distanceCoins / 4)
            lines.append(RewardLine(label: "NEW BEST", amount: bonus, isHighlight: true))
            totalCoins += bonus
        }

        if isFirstGameOfDay {
            lines.append(RewardLine(label: "FIRST RUN TODAY", amount: 10, isHighlight: true))
            totalCoins += 10
        }

        var xpBonus = 10 // Base completion bonus
        if score >= 500 {
            xpBonus += 50
        } else if score >= 100 {
            xpBonus += 20
        }
        if isNewHighScore {
            xpBonus += 50
        }
        if streak >= 7 {
            xpBonus += 25
        }
        if isFirstGameOfDay {
            xpBonus += 15
        }

        return GameReward(
            lines: lines,
            totalCoins: totalCoins,
            baseXP: score / 5,
            bonusXP: xpBonus,
            isFirstGameOfDay: isFirstGameOfDay,
            isNewHighScore: isNewHighScore
        )
    }
}
