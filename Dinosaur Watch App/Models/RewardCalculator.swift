import Foundation

struct GameReward {
    let baseCoins: Int
    let bonusCoins: Int
    let baseXP: Int
    let bonusXP: Int
    let isFirstGameOfDay: Bool
    let isNewHighScore: Bool

    var totalCoins: Int { baseCoins + bonusCoins }
    var totalXP: Int { baseXP + bonusXP }
}

struct RewardCalculator {
    static func calculate(
        score: Int,
        streak: Int,
        isNewHighScore: Bool,
        lastDailyBonusDate: Double
    ) -> GameReward {
        // Check if first game of day
        let isFirstGameOfDay = !Calendar.current.isDateInToday(
            Date(timeIntervalSince1970: lastDailyBonusDate)
        )

        // Base calculations
        let baseCoins = score / 10
        let baseXP = score / 5

        // Coin bonuses
        var coinBonus = 0

        // Score milestone bonus
        if score >= 1000 {
            coinBonus += 50
        } else if score >= 500 {
            coinBonus += 30
        } else if score >= 200 {
            coinBonus += 15
        } else if score >= 100 {
            coinBonus += 5
        }

        // New high score bonus (25% of base)
        if isNewHighScore && baseCoins > 0 {
            coinBonus += max(1, baseCoins / 4)
        }

        // Streak bonus
        if streak >= 14 {
            coinBonus += baseCoins * 30 / 100
        } else if streak >= 7 {
            coinBonus += baseCoins * 20 / 100
        } else if streak >= 3 {
            coinBonus += baseCoins * 10 / 100
        }

        // First game of day
        if isFirstGameOfDay {
            coinBonus += 10
        }

        // XP bonuses
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
            baseCoins: baseCoins,
            bonusCoins: coinBonus,
            baseXP: baseXP,
            bonusXP: xpBonus,
            isFirstGameOfDay: isFirstGameOfDay,
            isNewHighScore: isNewHighScore
        )
    }
}
