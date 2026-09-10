import SwiftUI

extension Font {
    /// Bricolage Grotesque — headings, titles, labels.
    static func heading(size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        switch weight {
        case .heavy, .black, .bold:
            return .custom("BricolageGrotesque-ExtraBold", size: size)
        default:
            return .custom("BricolageGrotesque-Bold", size: size)
        }
    }

    /// DM Mono — numerals, scores, stats.
    static func numeral(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .semibold, .medium, .bold, .heavy:
            return .custom("DM Mono Medium", size: size)
        default:
            return .custom("DM Mono", size: size)
        }
    }
}
