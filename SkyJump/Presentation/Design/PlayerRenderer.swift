import SwiftUI

/// Малює персонажа в обраному скіні і слід за ним. Використовується і в грі, і в меню персоналізації.
enum PlayerRenderer {

    /// Поза персонажа для одного кадру.
    struct Pose {
        var centerX: CGFloat
        var feetY: CGFloat
        var width: CGFloat
        var isFalling: Bool
        var hasJetpack: Bool
        var flicker: CGFloat          // 0…1 — «тремтіння» полум'я джетпака
    }

    private struct SkinColors {
        let top: Color
        let bottom: Color
    }

    private static func colors(for skin: PlayerSkin) -> SkinColors {
        switch skin {
        case .shades:
            return SkinColors(top: Theme.sunYellow, bottom: Theme.sunsetOrange)
        case .diver:
            return SkinColors(top: Color(red: 0.55, green: 0.95, blue: 0.85), bottom: Color(red: 0.10, green: 0.65, blue: 0.70))
        case .detective:
            return SkinColors(top: Color(red: 0.62, green: 0.64, blue: 0.70), bottom: Color(red: 0.35, green: 0.36, blue: 0.42))
        case .laurel:
            return SkinColors(top: Color(red: 0.99, green: 0.97, blue: 0.92), bottom: Color(red: 0.88, green: 0.82, blue: 0.70))
        case .doodle:
            return SkinColors(top: Color(red: 0.75, green: 0.92, blue: 0.35), bottom: Color(red: 0.50, green: 0.78, blue: 0.20))
        }
    }

    // MARK: - Персонаж

    static func draw(skin: PlayerSkin, pose: Pose, in context: inout GraphicsContext) {
        let width: CGFloat = pose.width
        let height: CGFloat = width * 1.1
        let body = CGRect(x: pose.centerX - width / 2, y: pose.feetY - height, width: width, height: height)
        let outline = Color(red: 0.08, green: 0.04, blue: 0.16).opacity(0.85)
        let line: CGFloat = max(width * 0.05, 1.5)

        if pose.hasJetpack {
            drawJetpack(body: body, flicker: pose.flicker, in: &context)
        }

        let palette = colors(for: skin)
        let bodyShape = Path(roundedRect: body, cornerRadius: width * 0.42)
        context.fill(bodyShape,
                     with: .linearGradient(Gradient(colors: [palette.top, palette.bottom]),
                                           startPoint: CGPoint(x: body.midX, y: body.minY),
                                           endPoint: CGPoint(x: body.midX, y: body.maxY)))
        context.stroke(bodyShape, with: .color(outline), lineWidth: line)

        // очі й аксесуари дивляться вниз, коли персонаж падає
        let eyesY: CGFloat = body.minY + height * (pose.isFalling ? 0.38 : 0.28)

        switch skin {
        case .shades:
            drawShades(body: body, eyesY: eyesY, in: &context)
        case .diver:
            drawDiverMask(body: body, eyesY: eyesY, line: line, in: &context)
        case .detective:
            drawEyes(body: body, eyesY: eyesY, isFalling: pose.isFalling, in: &context)
            drawHat(body: body, in: &context)
        case .laurel:
            drawEyes(body: body, eyesY: eyesY, isFalling: pose.isFalling, in: &context)
            drawLaurel(body: body, line: line, in: &context)
        case .doodle:
            drawEyes(body: body, eyesY: eyesY, isFalling: pose.isFalling, in: &context)
        }

        switch skin {
        case .diver:
            break
        case .doodle:
            drawCigarette(body: body, mouthY: eyesY + width * 0.38, phase: pose.flicker,
                          outline: outline, line: line, in: &context)
        default:
            drawSmile(body: body, y: eyesY + width * 0.34, line: line, in: &context)
        }
    }

    private static func drawJetpack(body: CGRect, flicker: CGFloat, in context: inout GraphicsContext) {
        let width = body.width
        let height = body.height
        let pack = CGRect(x: body.minX - width * 0.22, y: body.minY + height * 0.25,
                          width: width * 0.3, height: height * 0.55)
        context.fill(Path(roundedRect: pack, cornerRadius: width * 0.08), with: .color(Color(white: 0.82)))
        let flameLength: CGFloat = height * (0.45 + 0.25 * flicker)
        var flame = Path()
        flame.move(to: CGPoint(x: pack.minX + 2, y: pack.maxY))
        flame.addLine(to: CGPoint(x: pack.midX, y: pack.maxY + flameLength))
        flame.addLine(to: CGPoint(x: pack.maxX - 2, y: pack.maxY))
        flame.closeSubpath()
        context.fill(flame, with: .linearGradient(Gradient(colors: [Theme.sunYellow, Theme.sunsetOrange, .clear]),
                                                  startPoint: CGPoint(x: pack.midX, y: pack.maxY),
                                                  endPoint: CGPoint(x: pack.midX, y: pack.maxY + height * 0.7)))
    }

    private static func drawShades(body: CGRect, eyesY: CGFloat, in context: inout GraphicsContext) {
        let width = body.width
        let lens: CGFloat = width * 0.3
        let bridge = CGRect(x: body.midX - width * 0.36, y: eyesY + lens * 0.25, width: width * 0.72, height: lens * 0.18)
        context.fill(Path(bridge), with: .color(.black))
        for side in [CGFloat(-1), CGFloat(1)] {
            let lensRect = CGRect(x: body.midX + side * width * 0.2 - lens / 2, y: eyesY, width: lens, height: lens * 0.72)
            context.fill(Path(roundedRect: lensRect, cornerRadius: lens * 0.25), with: .color(.black))
            let shine = CGRect(x: lensRect.minX + lens * 0.18, y: lensRect.minY + lens * 0.14,
                               width: lens * 0.3, height: lens * 0.12)
            context.fill(Path(roundedRect: shine, cornerRadius: lens * 0.06), with: .color(Theme.neonPink.opacity(0.9)))
        }
    }

    private static func drawEyes(body: CGRect, eyesY: CGFloat, isFalling: Bool, in context: inout GraphicsContext) {
        let width = body.width
        let eye: CGFloat = width * 0.24
        for side in [CGFloat(-1), CGFloat(1)] {
            let rect = CGRect(x: body.midX + side * width * 0.18 - eye / 2, y: eyesY, width: eye, height: eye)
            context.fill(Path(ellipseIn: rect), with: .color(.white))
            let pupilShift: CGFloat = (isFalling ? 1 : -1) * eye * 0.15
            let pupil = rect.insetBy(dx: eye * 0.28, dy: eye * 0.28).offsetBy(dx: 0, dy: pupilShift)
            context.fill(Path(ellipseIn: pupil), with: .color(.black))
        }
    }

    private static func drawDiverMask(body: CGRect, eyesY: CGFloat, line: CGFloat, in context: inout GraphicsContext) {
        let width = body.width
        let mask = CGRect(x: body.midX - width * 0.36, y: eyesY - width * 0.04, width: width * 0.72, height: width * 0.34)
        context.fill(Path(roundedRect: mask, cornerRadius: width * 0.12), with: .color(Color(red: 0.70, green: 0.92, blue: 1.0).opacity(0.85)))
        context.stroke(Path(roundedRect: mask, cornerRadius: width * 0.12), with: .color(Color(red: 1.0, green: 0.55, blue: 0.2)), lineWidth: line * 1.4)
        drawEyes(body: body, eyesY: eyesY + width * 0.03, isFalling: false, in: &context)
        // трубка
        var snorkel = Path()
        snorkel.move(to: CGPoint(x: mask.maxX - width * 0.04, y: mask.midY))
        snorkel.addLine(to: CGPoint(x: body.maxX + width * 0.08, y: mask.midY))
        snorkel.addLine(to: CGPoint(x: body.maxX + width * 0.08, y: body.minY - width * 0.15))
        context.stroke(snorkel, with: .color(Color(red: 1.0, green: 0.85, blue: 0.2)),
                       style: StrokeStyle(lineWidth: line * 1.6, lineCap: .round, lineJoin: .round))
    }

    private static func drawHat(body: CGRect, in context: inout GraphicsContext) {
        let width = body.width
        let hatColor = Color(red: 0.12, green: 0.11, blue: 0.14)
        let brim = CGRect(x: body.midX - width * 0.55, y: body.minY + width * 0.02, width: width * 1.1, height: width * 0.1)
        let crown = CGRect(x: body.midX - width * 0.32, y: body.minY - width * 0.24, width: width * 0.64, height: width * 0.3)
        context.fill(Path(roundedRect: crown, cornerRadius: width * 0.08), with: .color(hatColor))
        context.fill(Path(roundedRect: brim, cornerRadius: width * 0.05), with: .color(hatColor))
        let band = CGRect(x: crown.minX, y: crown.maxY - width * 0.09, width: crown.width, height: width * 0.06)
        context.fill(Path(band), with: .color(Color(red: 0.85, green: 0.20, blue: 0.25)))
    }

    private static func drawLaurel(body: CGRect, line: CGFloat, in context: inout GraphicsContext) {
        let width = body.width
        let gold = Color(red: 0.98, green: 0.76, blue: 0.26)
        var leaves = Path()
        for side in [CGFloat(-1), CGFloat(1)] {
            for index in 0..<4 {
                let t: CGFloat = CGFloat(index) / 3
                let x: CGFloat = body.midX + side * width * (0.12 + t * 0.34)
                let y: CGFloat = body.minY + width * (0.02 + t * 0.12)
                leaves.addEllipse(in: CGRect(x: x - width * 0.07, y: y - width * 0.04, width: width * 0.14, height: width * 0.08))
            }
        }
        context.fill(leaves, with: .color(gold))
    }

    /// Цигарка, затиснута в кутику рота: трохи звисає донизу, фільтр ховається між губами,
    /// а з кінчика в'ється дим. phase зсуває хвилі диму від кадру до кадру.
    private static func drawCigarette(body: CGRect, mouthY: CGFloat, phase: CGFloat, outline: Color,
                                      line: CGFloat, in context: inout GraphicsContext) {
        let width = body.width
        let mouth = CGPoint(x: body.midX + width * 0.08, y: mouthY)

        // кривувата усмішка, що закінчується там, де затиснута цигарка
        var smirk = Path()
        smirk.move(to: CGPoint(x: body.midX - width * 0.14, y: mouthY - width * 0.02))
        smirk.addQuadCurve(to: mouth, control: CGPoint(x: body.midX - width * 0.03, y: mouthY + width * 0.06))
        context.stroke(smirk, with: .color(.black.opacity(0.75)), style: StrokeStyle(lineWidth: line, lineCap: .round))

        // цигарка малюється в повернутій системі координат: початок — у роті, нахил 14° донизу
        let length: CGFloat = width * 0.5
        let thickness: CGFloat = width * 0.09
        let angle = Angle.degrees(14)
        var stick = context
        stick.translateBy(x: mouth.x, y: mouth.y)
        stick.rotate(by: angle)

        let filter = CGRect(x: -length * 0.08, y: -thickness / 2, width: length * 0.32, height: thickness)
        let paper = CGRect(x: filter.maxX, y: filter.minY, width: length * 0.6, height: thickness)
        let ember = CGRect(x: paper.maxX, y: filter.minY, width: length * 0.08, height: thickness)
        stick.fill(Path(roundedRect: filter, cornerRadius: thickness * 0.2),
                   with: .color(Color(red: 0.93, green: 0.60, blue: 0.25)))
        stick.fill(Path(paper), with: .color(.white))
        stick.fill(Path(roundedRect: ember, cornerRadius: thickness * 0.3),
                   with: .color(Color(red: 1.0, green: 0.30, blue: 0.15)))
        let whole = CGRect(x: filter.minX, y: filter.minY, width: ember.maxX - filter.minX, height: thickness)
        stick.stroke(Path(roundedRect: whole, cornerRadius: thickness * 0.3), with: .color(outline),
                     lineWidth: line * 0.6)

        // губи поверх фільтра — цигарка «в роті», а не прикладена збоку
        let lips = CGRect(x: mouth.x - width * 0.06, y: mouth.y - width * 0.055, width: width * 0.12, height: width * 0.11)
        context.fill(Path(ellipseIn: lips), with: .color(Color(red: 0.42, green: 0.62, blue: 0.16)))
        context.stroke(Path(ellipseIn: lips), with: .color(.black.opacity(0.75)), lineWidth: line * 0.8)

        // кінчик у звичайних координатах: повертаємо точку так само, як цигарку
        let tipDistance: CGFloat = ember.midX
        let radians = CGFloat(angle.radians)
        let tip = CGPoint(x: mouth.x + tipDistance * cos(radians),
                          y: mouth.y + tipDistance * sin(radians) - thickness / 2)

        // дим: дві хвилясті цівки, що розсіюються вгорі
        let rise: CGFloat = width * 0.9
        for (index, sway) in [CGFloat(1), CGFloat(-0.7)].enumerated() {
            let offset: CGFloat = CGFloat(index) * width * 0.08
            let wave: CGFloat = width * 0.12 * sway * (phase * 2 - 1)
            var smoke = Path()
            smoke.move(to: CGPoint(x: tip.x + offset * 0.3, y: tip.y))
            smoke.addCurve(to: CGPoint(x: tip.x + offset + width * 0.05, y: tip.y - rise),
                           control1: CGPoint(x: tip.x + width * 0.18 + wave, y: tip.y - rise * 0.3),
                           control2: CGPoint(x: tip.x - width * 0.14 - wave, y: tip.y - rise * 0.65))
            context.stroke(smoke,
                           with: .linearGradient(Gradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0)]),
                                                 startPoint: tip,
                                                 endPoint: CGPoint(x: tip.x, y: tip.y - rise)),
                           style: StrokeStyle(lineWidth: max(line * (1.4 - CGFloat(index) * 0.4), 1), lineCap: .round))
        }
    }

    private static func drawSmile(body: CGRect, y: CGFloat, line: CGFloat, in context: inout GraphicsContext) {
        let width = body.width
        var smile = Path()
        smile.move(to: CGPoint(x: body.midX - width * 0.12, y: y))
        smile.addQuadCurve(to: CGPoint(x: body.midX + width * 0.12, y: y),
                           control: CGPoint(x: body.midX, y: y + width * 0.1))
        context.stroke(smile, with: .color(.black.opacity(0.75)), style: StrokeStyle(lineWidth: line, lineCap: .round))
    }

    // MARK: - Слід

    /// points — точки сліду в координатах екрана від найстарішої до найновішої.
    static func drawTrail(_ style: TrailStyle, points: [CGPoint], width: CGFloat, color: Color,
                          in context: inout GraphicsContext) {
        guard style != .none, points.count > 1 else { return }
        let count = CGFloat(points.count)

        switch style {
        case .none:
            break
        case .neon:
            // кожен відрізок трохи прозоріший і тонший за попередній
            for index in 1..<points.count {
                let t: CGFloat = CGFloat(index) / count
                var segment = Path()
                segment.move(to: points[index - 1])
                segment.addLine(to: points[index])
                context.stroke(segment, with: .color(color.opacity(Double(t) * 0.8)),
                               style: StrokeStyle(lineWidth: width * 0.35 * t, lineCap: .round))
            }
        case .sparkles:
            for (index, point) in points.enumerated() {
                let t: CGFloat = CGFloat(index + 1) / count
                let size: CGFloat = width * 0.18 * t
                var star = Path()
                star.move(to: CGPoint(x: point.x, y: point.y - size))
                star.addLine(to: CGPoint(x: point.x + size * 0.3, y: point.y - size * 0.3))
                star.addLine(to: CGPoint(x: point.x + size, y: point.y))
                star.addLine(to: CGPoint(x: point.x + size * 0.3, y: point.y + size * 0.3))
                star.addLine(to: CGPoint(x: point.x, y: point.y + size))
                star.addLine(to: CGPoint(x: point.x - size * 0.3, y: point.y + size * 0.3))
                star.addLine(to: CGPoint(x: point.x - size, y: point.y))
                star.addLine(to: CGPoint(x: point.x - size * 0.3, y: point.y - size * 0.3))
                star.closeSubpath()
                context.fill(star, with: .color(Theme.sunYellow.opacity(Double(t))))
            }
        case .bubbles:
            var bubbles = Path()
            for (index, point) in points.enumerated() where index.isMultiple(of: 2) {
                let t: CGFloat = CGFloat(index + 1) / count
                let diameter: CGFloat = width * (0.12 + 0.15 * (1 - t))
                bubbles.addEllipse(in: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2,
                                              width: diameter, height: diameter))
            }
            context.stroke(bubbles, with: .color(.white.opacity(0.8)), lineWidth: max(width * 0.04, 1))
        case .stars:
            for (index, point) in points.enumerated() where index.isMultiple(of: 3) {
                let t: CGFloat = CGFloat(index + 1) / count
                let size: CGFloat = width * 0.28 * t
                let star = Text("⭐️").font(.system(size: size))
                context.opacity = Double(t)
                context.draw(star, at: point)
            }
            context.opacity = 1
        }
    }
}
