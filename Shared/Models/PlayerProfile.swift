import SwiftUI

// MARK: - Dinosaur Skins

enum DinosaurSkin: String, CaseIterable, Codable, Identifiable {
    case squaresaurus
    case spike
    case chrome
    case mechRex
    case dragon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squaresaurus: return "Squaresaurus"
        case .spike: return "Spike"
        case .chrome: return "Chrome"
        case .mechRex: return "Mech-Rex"
        case .dragon: return "Dragon"
        }
    }

    var evolutionLevel: Int {
        switch self {
        case .squaresaurus: return 1
        case .spike: return 2
        case .chrome: return 3
        case .mechRex: return 4
        case .dragon: return 5
        }
    }

    var previousSkin: DinosaurSkin? {
        switch self {
        case .squaresaurus: return nil
        case .spike: return .squaresaurus
        case .chrome: return .spike
        case .mechRex: return .chrome
        case .dragon: return .mechRex
        }
    }

    var coinCost: Int {
        switch self {
        case .squaresaurus: return 0
        case .spike: return 100
        case .chrome: return 300
        case .mechRex: return 600
        case .dragon: return 1000
        }
    }

    var requiredPlayerLevel: Int {
        switch self {
        case .squaresaurus: return 1
        case .spike: return 3
        case .chrome: return 6
        case .mechRex: return 10
        case .dragon: return 15
        }
    }

    var primaryColor: Color {
        switch self {
        case .squaresaurus: return .green
        case .spike: return .blue
        case .chrome: return Color(white: 0.75)
        case .mechRex: return .orange
        case .dragon: return .purple
        }
    }

    var eyeColor: Color {
        switch self {
        case .squaresaurus: return .white
        case .spike: return .yellow
        case .chrome: return .red
        case .mechRex: return .cyan
        case .dragon: return .yellow
        }
    }
}

// MARK: - Obstacle Skins

enum ObstacleSkin: String, CaseIterable, Codable, Identifiable {
    case cactus
    case crystal
    case lavaRock

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cactus: return "Cactus"
        case .crystal: return "Crystal"
        case .lavaRock: return "Lava Rock"
        }
    }

    var evolutionLevel: Int {
        switch self {
        case .cactus: return 1
        case .crystal: return 2
        case .lavaRock: return 3
        }
    }

    var previousSkin: ObstacleSkin? {
        switch self {
        case .cactus: return nil
        case .crystal: return .cactus
        case .lavaRock: return .crystal
        }
    }

    var coinCost: Int {
        switch self {
        case .cactus: return 0
        case .crystal: return 150
        case .lavaRock: return 400
        }
    }

    var requiredPlayerLevel: Int {
        switch self {
        case .cactus: return 1
        case .crystal: return 4
        case .lavaRock: return 8
        }
    }

    var primaryColor: Color {
        switch self {
        case .cactus: return .red
        case .crystal: return .cyan
        case .lavaRock: return Color(red: 0.8, green: 0.2, blue: 0.1)
        }
    }
}

// MARK: - Background Skins

enum BackgroundSkin: String, CaseIterable, Codable, Identifiable {
    case desertNight
    case neonCity
    case volcano

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .desertNight: return "Desert Night"
        case .neonCity: return "Neon City"
        case .volcano: return "Volcano"
        }
    }

    var evolutionLevel: Int {
        switch self {
        case .desertNight: return 1
        case .neonCity: return 2
        case .volcano: return 3
        }
    }

    var previousSkin: BackgroundSkin? {
        switch self {
        case .desertNight: return nil
        case .neonCity: return .desertNight
        case .volcano: return .neonCity
        }
    }

    var coinCost: Int {
        switch self {
        case .desertNight: return 0
        case .neonCity: return 200
        case .volcano: return 500
        }
    }

    var requiredPlayerLevel: Int {
        switch self {
        case .desertNight: return 1
        case .neonCity: return 5
        case .volcano: return 12
        }
    }

    var backgroundColor: Color {
        switch self {
        case .desertNight: return .black
        case .neonCity: return Color(red: 0.05, green: 0.05, blue: 0.2)
        case .volcano: return Color(red: 0.15, green: 0.02, blue: 0.02)
        }
    }

    var groundColor: Color {
        switch self {
        case .desertNight: return .gray
        case .neonCity: return .cyan
        case .volcano: return .orange
        }
    }
}
