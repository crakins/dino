import SwiftUI

enum PandaGraphics {
    /// Draws the panda mark (36x26 design units) into `rect`, uniformly scaled, optionally rotated about its center.
    /// `accentColor` recolors the panda's markings (ear, eye patch, legs) — the whole silhouette,
    /// not just the ear — so each equipped Kin reads as a distinct color even at in-game sprite
    /// size. Defaults to the standard black-and-white panda.
    static func drawPanda(_ context: inout GraphicsContext, in rect: CGRect, rotationDegrees: Double = 0, accentColor: Color = PandaColor.pandaBlack) {
        let scale = min(rect.width / 36, rect.height / 26)

        func rounded(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) -> Path {
            Path(roundedRect: CGRect(x: rect.minX + x * scale, y: rect.minY + y * scale, width: w * scale, height: h * scale), cornerRadius: r * scale)
        }
        func circle(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: rect.minX + (cx - r) * scale, y: rect.minY + (cy - r) * scale, width: 2 * r * scale, height: 2 * r * scale))
        }
        func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: rect.minX + (cx - rx) * scale, y: rect.minY + (cy - ry) * scale, width: 2 * rx * scale, height: 2 * ry * scale))
        }

        context.drawLayer { layer in
            if rotationDegrees != 0 {
                let anchor = CGPoint(x: rect.midX, y: rect.midY)
                layer.translateBy(x: anchor.x, y: anchor.y)
                layer.rotate(by: .degrees(rotationDegrees))
                layer.translateBy(x: -anchor.x, y: -anchor.y)
            }

            layer.fill(circle(cx: 5.5, cy: 12, r: 2.4), with: .color(PandaColor.white))
            layer.fill(rounded(x: 8, y: 16, w: 4.5, h: 9, r: 2.2), with: .color(accentColor))
            layer.fill(rounded(x: 6, y: 8, w: 18, h: 11, r: 5), with: .color(PandaColor.white))
            layer.fill(rounded(x: 9.5, y: 8, w: 6.5, h: 9, r: 3.2), with: .color(accentColor))
            layer.fill(circle(cx: 24.6, cy: 6.6, r: 2.7), with: .color(accentColor))
            layer.fill(circle(cx: 27, cy: 12, r: 6), with: .color(PandaColor.white))
            layer.fill(ellipse(cx: 28.6, cy: 10.8, rx: 2, ry: 2.4), with: .color(accentColor))
            layer.fill(circle(cx: 28.8, cy: 10.4, r: 0.7), with: .color(PandaColor.white))
            layer.fill(circle(cx: 32, cy: 13, r: 1.1), with: .color(PandaColor.pandaBlack))
            layer.fill(rounded(x: 16.5, y: 16, w: 4.5, h: 9, r: 2.2), with: .color(accentColor))
        }
    }

    /// Draws the front-facing 24x24 head mark shared by the app icon, market tiles and complications.
    /// `earColor` differentiates Kin evolution stages; defaults to the standard panda-black.
    /// `accessory` and `expression` are Market-only flourishes (a scarf, a grin, ...) that make
    /// each stage feel distinct at a glance — the in-game sprite (`drawPanda`) never uses them,
    /// so gameplay stays visually simple and consistent across every Kin.
    static func drawHeadMark(
        _ context: inout GraphicsContext,
        in rect: CGRect,
        earColor: Color = PandaColor.pandaBlack,
        accessory: KinAccessory = .none,
        expression: KinExpression = .content
    ) {
        let size = min(rect.width, rect.height)
        let scale = size / 24
        let originX = rect.midX - 12 * scale
        let originY = rect.midY - 12 * scale

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: originX + x * scale, y: originY + y * scale)
        }
        func circle(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: originX + (cx - r) * scale, y: originY + (cy - r) * scale, width: 2 * r * scale, height: 2 * r * scale))
        }
        func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: originX + (cx - rx) * scale, y: originY + (cy - ry) * scale, width: 2 * rx * scale, height: 2 * ry * scale))
        }

        // Tail and leaf sit behind the head so they read as "peeking out" rather than pasted on top.
        if accessory == .tail {
            var tail = Path()
            tail.move(to: point(19.5, 16))
            tail.addQuadCurve(to: point(23, 18.5), control: point(23, 14.5))
            tail.addQuadCurve(to: point(20, 19.5), control: point(21, 20))
            context.fill(tail, with: .color(PandaColor.kinEmber))
        }
        if accessory == .leaf {
            var leaf = Path()
            leaf.move(to: point(21.5, 2.5))
            leaf.addQuadCurve(to: point(23.5, 6), control: point(24.5, 3.5))
            leaf.addQuadCurve(to: point(21.5, 2.5), control: point(21.5, 5))
            leaf.closeSubpath()
            context.fill(leaf, with: .color(PandaColor.kinMoss))
        }

        context.fill(circle(cx: 5, cy: 4.6, r: 3.5), with: .color(earColor))
        context.fill(circle(cx: 19, cy: 4.6, r: 3.5), with: .color(earColor))
        context.fill(circle(cx: 12, cy: 13, r: 9), with: .color(PandaColor.white))
        context.fill(ellipse(cx: 8.3, cy: 11.4, rx: 2.5, ry: 2.9), with: .color(PandaColor.pandaBlack))
        context.fill(ellipse(cx: 15.7, cy: 11.4, rx: 2.5, ry: 2.9), with: .color(PandaColor.pandaBlack))
        context.fill(circle(cx: 8.3, cy: 11, r: 0.8), with: .color(PandaColor.white))
        context.fill(circle(cx: 15.7, cy: 11, r: 0.8), with: .color(PandaColor.white))
        context.fill(ellipse(cx: 12, cy: 16.4, rx: 1.7, ry: 1.2), with: .color(PandaColor.pandaBlack))

        drawSmile(&context, point: point, expression: expression, scale: scale)

        switch accessory {
        case .none, .leaf, .tail:
            break
        case .collar:
            var collar = Path()
            collar.move(to: point(4.5, 19.5))
            collar.addQuadCurve(to: point(19.5, 19.5), control: point(12, 23.5))
            context.stroke(collar, with: .color(PandaColor.green), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
        case .scarf:
            var scarf = Path()
            scarf.move(to: point(5, 19))
            scarf.addQuadCurve(to: point(19, 19), control: point(12, 22.5))
            context.stroke(scarf, with: .color(PandaColor.kinAmber), style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
            // Knot hanging below the wrap.
            var knot = Path()
            knot.move(to: point(10.5, 20.5))
            knot.addLine(to: point(9, 24))
            knot.addLine(to: point(12, 21.5))
            knot.closeSubpath()
            context.fill(knot, with: .color(PandaColor.kinAmber))
        }
    }

    private static func drawSmile(_ context: inout GraphicsContext, point: (CGFloat, CGFloat) -> CGPoint, expression: KinExpression, scale: CGFloat) {
        var smile = Path()
        switch expression {
        case .content:
            smile.move(to: point(9.5, 18.2))
            smile.addQuadCurve(to: point(14.5, 18.2), control: point(12, 19.6))
        case .grin:
            smile.move(to: point(8.7, 17.8))
            smile.addQuadCurve(to: point(15.3, 17.8), control: point(12, 20.6))
        case .smirk:
            smile.move(to: point(9.5, 18.4))
            smile.addQuadCurve(to: point(14.8, 17.6), control: point(12.5, 19.8))
        }
        context.stroke(smile, with: .color(PandaColor.pandaBlack.opacity(0.55)), style: StrokeStyle(lineWidth: 0.9 * scale, lineCap: .round))
    }
}
