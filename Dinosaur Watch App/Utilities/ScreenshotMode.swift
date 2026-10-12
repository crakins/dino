import SwiftUI

extension View {
    /// In screenshot mode, starts a scroll view at `y` (0 = top, 1 = bottom) so content clears
    /// the bottom bar (simctl can't scroll). A no-op otherwise, and compiled out of release builds.
    func screenshotScrollAnchor(y: CGFloat) -> some View {
        #if DEBUG
        defaultScrollAnchor(ScreenshotScene.current == nil ? .top : UnitPoint(x: 0.5, y: y))
        #else
        self
        #endif
    }
}

#if DEBUG

/// Debug-only App Store screenshot staging. Launch with `-screenshot <scene>` (e.g. via
/// `xcrun simctl launch <device> com.a6enterprises.Dinosaur.watchkitapp -screenshot quest`)
/// to seed a consistent demo profile and open straight onto that screen.
enum ScreenshotScene: String {
    case home, quest, jadepaw, runEnded

    static let current: ScreenshotScene? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return ScreenshotScene(rawValue: args[i + 1])
    }()

    /// Demo run shown on the Run Ended screen.
    static let runScore = 468
    static let runShoots = 17
    static let runSeconds = 38

    /// Writes the demo profile into UserDefaults. Must run before ContentView reads storage.
    static func seedDefaults() {
        let defaults = UserDefaults.standard
        let now = Date().timeIntervalSince1970
        defaults.set(842, forKey: "highScore")
        defaults.set(5, forKey: "currentStreak")
        defaults.set(now, forKey: "lastPlayedDate")

        var data = PlayerData()
        data.coins = 385
        data.totalXP = 2050 // LV 7
        data.gamesPlayed = 64
        data.ownedKin = [Kin.panda.rawValue, Kin.reedpaw.rawValue]
        data.ownedWorlds = [World.bambooGrove.rawValue, World.mistTerraces.rawValue, World.snowPass.rawValue]
        data.lastDailyBonusDate = now
        data.dailyQuestDate = now
        data.dailyQuestProgress = 2
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "playerData")
        }
    }
}
#endif
