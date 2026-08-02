import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum PandaColor {
    static let ink = Color(hex: 0x0E100E)
    static let inkRaised = Color(hex: 0x1A1D1A)
    static let inkSunken = Color(hex: 0x141614)
    static let bannerTop = Color(hex: 0x191C19)
    static let pandaBlack = Color(hex: 0x2E322E)
    static let white = Color(hex: 0xF4F6F3)
    static let green = Color(hex: 0x6FBE7E)
    static let greenPale = Color(hex: 0xA8D8B0)
    static let greenMint = Color(hex: 0xB9E3C1)
    static let greenIce = Color(hex: 0xCFE9D4)
    static let greenDeep = Color(hex: 0x4E8C5C)
    static let grey = Color(hex: 0x9AA79C)
}
