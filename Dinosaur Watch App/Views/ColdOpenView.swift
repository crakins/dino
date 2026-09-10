import SwiftUI

/// Launch splash — the panda is already running before you've read anything.
/// Loops seamlessly for as long as it's shown, then hands off to the home screen.
struct ColdOpenView: View {
    var pandaAccentColor: Color = PandaColor.pandaBlack
    let onComplete: () -> Void

    private let minimumDuration: TimeInterval = 1.4

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                render(context: context, size: size, now: timeline.date)
            }
        }
        .background(PandaColor.ink)
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumDuration) {
                onComplete()
            }
        }
    }

    private func render(context: GraphicsContext, size: CGSize, now: Date) {
        let t = now.timeIntervalSinceReferenceDate

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [PandaColor.bannerTop, PandaColor.ink]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height * 0.58)
            )
        )

        // Wordmark
        context.draw(
            Text("PANDA")
                .font(.heading(size: 26, weight: .heavy))
                .foregroundColor(PandaColor.white),
            at: CGPoint(x: size.width / 2, y: 62 + 13),
            anchor: .center
        )
        context.draw(
            Text("PANDA")
                .font(.heading(size: 26, weight: .heavy))
                .foregroundColor(PandaColor.green),
            at: CGPoint(x: size.width / 2, y: 62 + 13 + 22),
            anchor: .center
        )

        // Ambient dots
        renderDot(context: context, at: CGPoint(x: 20, y: 40), radius: 1.5, opacity: 0.4)
        renderDot(context: context, at: CGPoint(x: size.width - 34, y: 30), radius: 1, opacity: 0.3)

        let groundY = size.height - 42

        // Mountain silhouette
        let peaks: [(w: CGFloat, h: CGFloat, opacity: Double)] = [(52, 16, 0.16), (68, 24, 0.12), (67, 13, 0.14)]
        var cursor: CGFloat = 0
        for peak in peaks {
            var path = Path()
            path.move(to: CGPoint(x: cursor, y: groundY - 2))
            path.addLine(to: CGPoint(x: cursor + peak.w * 0.4, y: groundY - 2 - peak.h))
            path.addLine(to: CGPoint(x: cursor + peak.w, y: groundY - 2))
            path.closeSubpath()
            context.fill(path, with: .color(PandaColor.green.opacity(peak.opacity)))
            cursor += peak.w
        }

        // Ground line
        context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 1)), with: .color(PandaColor.green))

        // Scrolling ground dashes
        let dashPhase = CGFloat((t.truncatingRemainder(dividingBy: 0.9)) / 0.9) * 20
        var dash = Path()
        dash.move(to: CGPoint(x: -20 + dashPhase, y: groundY + 6))
        dash.addLine(to: CGPoint(x: size.width + 20, y: groundY + 6))
        context.stroke(dash, with: .color(PandaColor.green.opacity(0.5)), style: StrokeStyle(lineWidth: 2, dash: [10, 10]))

        // Panda: runs across, bobbing
        var context = context
        let acrossDuration: TimeInterval = 2.6
        let acrossPhase = CGFloat((t.truncatingRemainder(dividingBy: acrossDuration)) / acrossDuration)
        let pandaWidth: CGFloat = 32
        let pandaHeight: CGFloat = 23
        let x = -pandaWidth + acrossPhase * (size.width + pandaWidth * 2)
        let bob = abs(sin(t * (.pi / 0.38))) * 3
        let pandaRect = CGRect(x: x, y: groundY - 1 - pandaHeight - bob, width: pandaWidth, height: pandaHeight)
        PandaGraphics.drawPanda(&context, in: pandaRect, accentColor: pandaAccentColor)

        // Loading dots
        let dotY = size.height - 16
        let dotSpacing: CGFloat = 8
        let startX = size.width / 2 - dotSpacing
        for i in 0..<3 {
            let delay = Double(i) * 0.2
            let pulse = (sin((t - delay) * (2 * .pi / 1.2) - .pi / 2) + 1) / 2
            let opacity = 0.35 + 0.65 * pulse
            renderDot(context: context, at: CGPoint(x: startX + CGFloat(i) * dotSpacing, y: dotY), radius: 2, opacity: opacity, color: PandaColor.green)
        }
    }

    private func renderDot(context: GraphicsContext, at point: CGPoint, radius: CGFloat, opacity: Double, color: Color = PandaColor.greenMint) {
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(color.opacity(opacity))
        )
    }
}
