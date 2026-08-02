import SwiftUI
import WatchKit

struct CountdownView: View {
    let season: Season
    let onComplete: () -> Void

    @State private var count = 3
    @State private var beatStart = Date()

    private let beatDuration: TimeInterval = 0.8

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                render(context: context, size: size, now: timeline.date)
            }
        }
        .background(PandaColor.ink)
        .ignoresSafeArea()
        .onAppear { startCountdown() }
    }

    private func render(context: GraphicsContext, size: CGSize, now: Date) {
        let groundY = size.height - 38

        // Ground line
        context.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 1)), with: .color(PandaColor.green.opacity(0.45)))

        // Ground dashes
        var dash = Path()
        dash.move(to: CGPoint(x: 0, y: size.height - 32))
        dash.addLine(to: CGPoint(x: size.width, y: size.height - 32))
        context.stroke(dash, with: .color(PandaColor.green.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [10, 10]))

        // Ring
        let ringSize: CGFloat = 96
        let ringRect = CGRect(x: size.width / 2 - ringSize / 2, y: size.height / 2 - ringSize / 2, width: ringSize, height: ringSize)
        let center = CGPoint(x: ringRect.midX, y: ringRect.midY)

        context.stroke(Path(ellipseIn: ringRect), with: .color(PandaColor.white.opacity(0.1)), style: StrokeStyle(lineWidth: 3))

        let elapsed = now.timeIntervalSince(beatStart)
        let remaining = max(0, 1 - elapsed / beatDuration)
        if remaining > 0 {
            let full = Path(ellipseIn: ringRect)
            let trimmed = full.trimmedPath(from: 0, to: remaining)
            let rotate = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: -.pi / 2)
                .translatedBy(x: -center.x, y: -center.y)
            context.stroke(
                trimmed.applying(rotate),
                with: .color(PandaColor.green),
                style: StrokeStyle(lineWidth: 3, lineCap: .butt)
            )
        }

        context.draw(
            Text("\(count)")
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundColor(PandaColor.white),
            at: center,
            anchor: .center
        )

        // Panda, crouch-bobbing on the ground
        var context = context
        let bob = abs(sin(now.timeIntervalSinceReferenceDate * (Double.pi / 0.4))) * 3
        let pandaHeight: CGFloat = 23
        let pandaWidth: CGFloat = pandaHeight * 36 / 26
        let pandaRect = CGRect(x: 34, y: size.height - 39 - pandaHeight - bob, width: pandaWidth, height: pandaHeight)
        PandaGraphics.drawPanda(&context, in: pandaRect)

        // Caption
        context.draw(
            Text("\(season.displayName) · TAP TO LEAP")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(PandaColor.white.opacity(0.4))
                .tracking(1.2),
            at: CGPoint(x: size.width / 2, y: size.height - 14),
            anchor: .center
        )
    }

    private func startCountdown() {
        beatStart = Date()
        WKInterfaceDevice.current().play(.click)

        DispatchQueue.main.asyncAfter(deadline: .now() + beatDuration) {
            count = 2
            beatStart = Date()
            WKInterfaceDevice.current().play(.click)

            DispatchQueue.main.asyncAfter(deadline: .now() + beatDuration) {
                count = 1
                beatStart = Date()
                WKInterfaceDevice.current().play(.click)

                DispatchQueue.main.asyncAfter(deadline: .now() + beatDuration) {
                    WKInterfaceDevice.current().play(.start)
                    onComplete()
                }
            }
        }
    }
}
