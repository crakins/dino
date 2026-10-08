import SwiftUI

/// Pins a screen's primary actions to the bottom edge while the content above scrolls beneath.
/// Only the background bleeds into the unsafe/rounded-corner region — the buttons themselves
/// stay inset or they land in the bezel's touch dead-zone.
enum BottomBarLayout {
    /// Pulls the buttons down into the bottom safe-area inset, which on watchOS is much larger
    /// than the screen's rounded corners need — the bottom-edge counterpart to the app's -30 top
    /// pull. Shared with MenuView so Home's buttons sit at the same height as every other bar.
    static let bottomPull: CGFloat = -10

    /// Fill opacity for buttons inside a bottom bar — lets scrolled content show faintly through
    /// them, so it reads as scrollable rather than the buttons closing off the screen.
    static let fillOpacity: Double = 0.8
}

struct BottomBar<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, BottomBarLayout.bottomPull)
            .frame(maxWidth: .infinity)
            .background(
                // Dims scrolled content under the buttons without hiding it — stopping short of
                // opaque ink keeps it visible through the translucent button fills.
                LinearGradient(
                    colors: [PandaColor.ink.opacity(0), PandaColor.ink.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.35)
                )
                .ignoresSafeArea(edges: .bottom)
            )
    }
}

extension View {
    /// Attach to a `ScrollView` — the scroll content reserves room for the bar so its last line
    /// can scroll fully clear of the buttons.
    func bottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar { bar() }
        }
    }
}
