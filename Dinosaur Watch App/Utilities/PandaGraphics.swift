import SwiftUI

enum PandaGraphics {
    /// Draws the panda mark (36x26 design units) into `rect`, uniformly scaled, optionally rotated about its center.
    /// `earColor` differentiates the equipped Kin; defaults to the standard panda-black.
    static func drawPanda(_ context: inout GraphicsContext, in rect: CGRect, rotationDegrees: Double = 0, earColor: Color = PandaColor.pandaBlack) {
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
            layer.fill(rounded(x: 8, y: 16, w: 4.5, h: 9, r: 2.2), with: .color(PandaColor.pandaBlack))
            layer.fill(rounded(x: 6, y: 8, w: 18, h: 11, r: 5), with: .color(PandaColor.white))
            layer.fill(rounded(x: 9.5, y: 8, w: 6.5, h: 9, r: 3.2), with: .color(PandaColor.pandaBlack))
            layer.fill(circle(cx: 24.6, cy: 6.6, r: 2.7), with: .color(earColor))
            layer.fill(circle(cx: 27, cy: 12, r: 6), with: .color(PandaColor.white))
            layer.fill(ellipse(cx: 28.6, cy: 10.8, rx: 2, ry: 2.4), with: .color(PandaColor.pandaBlack))
            layer.fill(circle(cx: 28.8, cy: 10.4, r: 0.7), with: .color(PandaColor.white))
            layer.fill(circle(cx: 32, cy: 13, r: 1.1), with: .color(PandaColor.pandaBlack))
            layer.fill(rounded(x: 16.5, y: 16, w: 4.5, h: 9, r: 2.2), with: .color(PandaColor.pandaBlack))
        }
    }

    /// Draws the front-facing 24x24 head mark shared by the app icon, market tiles and complications.
    /// `earColor` differentiates Kin evolution stages; defaults to the standard panda-black.
    static func drawHeadMark(_ context: inout GraphicsContext, in rect: CGRect, earColor: Color = PandaColor.pandaBlack) {
        let size = min(rect.width, rect.height)
        let scale = size / 24
        let originX = rect.midX - 12 * scale
        let originY = rect.midY - 12 * scale

        func circle(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: originX + (cx - r) * scale, y: originY + (cy - r) * scale, width: 2 * r * scale, height: 2 * r * scale))
        }
        func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: originX + (cx - rx) * scale, y: originY + (cy - ry) * scale, width: 2 * rx * scale, height: 2 * ry * scale))
        }

        context.fill(circle(cx: 5, cy: 4.6, r: 3.5), with: .color(earColor))
        context.fill(circle(cx: 19, cy: 4.6, r: 3.5), with: .color(earColor))
        context.fill(circle(cx: 12, cy: 13, r: 9), with: .color(PandaColor.white))
        context.fill(ellipse(cx: 8.3, cy: 11.4, rx: 2.5, ry: 2.9), with: .color(PandaColor.pandaBlack))
        context.fill(ellipse(cx: 15.7, cy: 11.4, rx: 2.5, ry: 2.9), with: .color(PandaColor.pandaBlack))
        context.fill(circle(cx: 8.3, cy: 11, r: 0.8), with: .color(PandaColor.white))
        context.fill(circle(cx: 15.7, cy: 11, r: 0.8), with: .color(PandaColor.white))
        context.fill(ellipse(cx: 12, cy: 16.4, rx: 1.7, ry: 1.2), with: .color(PandaColor.pandaBlack))
    }
}
