import SwiftUI

/// Фон гри: неоновий пляж на заході сонця — небо-градієнт, смугасте сонце, силует міста,
/// море й пальми. Чим вище гравець, тим далі внизу лишається берег, а небо темніє до нічного з зорями.
enum NeonBeachBackground {

    /// cameraBottom — висота світу на нижньому краю екрана, scale — пікселів на одиницю світу.
    static func draw(in context: inout GraphicsContext, size: CGSize, cameraBottom: Double, scale: CGFloat) {
        let climb = max(cameraBottom + GameplayViewModel.cameraOffset, 0)
        let night = min(max((climb - 300) / 2500, 0), 1)

        drawSky(in: &context, size: size, night: night)
        drawStars(in: &context, size: size, night: night, climb: climb, scale: scale)

        // Горизонт «опускається», коли гравець піднімається (паралакс: дальній план рухається повільніше)
        let horizonY = size.height * 0.70 + CGFloat(climb) * 0.35 * scale
        guard horizonY < size.height + size.width else { return }

        drawSun(in: &context, size: size, horizonY: horizonY, night: night)
        drawSkyline(in: &context, size: size, horizonY: horizonY, night: night)
        drawSea(in: &context, size: size, horizonY: horizonY)

        let palmsBase = size.height * 1.03 + CGFloat(climb) * 0.6 * scale
        drawPalm(in: &context, base: CGPoint(x: size.width * 0.06, y: palmsBase),
                 height: size.height * 0.46, lean: size.width * 0.10)
        drawPalm(in: &context, base: CGPoint(x: size.width * 0.95, y: palmsBase + 20),
                 height: size.height * 0.40, lean: -size.width * 0.12)
        drawPalm(in: &context, base: CGPoint(x: size.width * 0.80, y: palmsBase + 30),
                 height: size.height * 0.28, lean: -size.width * 0.05)
    }

    // MARK: - Небо

    private struct RGB {
        let r: Double, g: Double, b: Double

        func mixed(with other: RGB, _ t: Double) -> Color {
            Color(red: r + (other.r - r) * t, green: g + (other.g - g) * t, blue: b + (other.b - b) * t)
        }
    }

    private static let daySky = [RGB(r: 0.30, g: 0.12, b: 0.50), RGB(r: 0.93, g: 0.30, b: 0.58), RGB(r: 1.00, g: 0.62, b: 0.36)]
    private static let nightSky = [RGB(r: 0.03, g: 0.02, b: 0.12), RGB(r: 0.10, g: 0.05, b: 0.28), RGB(r: 0.26, g: 0.10, b: 0.40)]

    private static func drawSky(in context: inout GraphicsContext, size: CGSize, night: Double) {
        let colors = zip(daySky, nightSky).map { day, dark in day.mixed(with: dark, night) }
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: colors),
                                           startPoint: .zero,
                                           endPoint: CGPoint(x: 0, y: size.height)))
    }

    /// Псевдовипадкове число 0…1 для сталого розташування зірок і будинків.
    private static func noise(_ seed: Double) -> Double {
        let value = sin(seed * 12.9898) * 43_758.5453
        return value - value.rounded(.down)
    }

    private static func drawStars(in context: inout GraphicsContext, size: CGSize,
                                  night: Double, climb: Double, scale: CGFloat) {
        guard night > 0.05 else { return }
        let drift = CGFloat(climb) * 0.05 * scale
        for index in 0..<70 {
            let x = CGFloat(noise(Double(index) + 0.5)) * size.width
            let rawY = CGFloat(noise(Double(index) * 7.31 + 3)) * size.height + drift
            let y = rawY.truncatingRemainder(dividingBy: size.height)
            let radius: CGFloat = noise(Double(index) * 3.7) > 0.8 ? 1.8 : 1.1
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                         with: .color(.white.opacity(0.85 * night)))
        }
    }

    // MARK: - Сонце, місто, море

    private static func drawSun(in context: inout GraphicsContext, size: CGSize, horizonY: CGFloat, night: Double) {
        let radius = size.width * 0.26
        let center = CGPoint(x: size.width * 0.5, y: horizonY - radius * 0.35)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        context.drawLayer { layer in
            layer.opacity = 1 - night * 0.85
            layer.fill(Path(ellipseIn: rect),
                       with: .linearGradient(Gradient(colors: [Theme.sunYellow, Theme.neonPink]),
                                             startPoint: CGPoint(x: center.x, y: rect.minY),
                                             endPoint: CGPoint(x: center.x, y: rect.maxY)))
            // смуги на нижній половині сонця — класика synthwave
            layer.blendMode = .destinationOut
            for stripe in 0..<6 {
                let y = center.y + radius * (0.05 + CGFloat(stripe) * 0.16)
                let height = 2 + CGFloat(stripe) * 1.6
                layer.fill(Path(CGRect(x: rect.minX, y: y, width: rect.width, height: height)), with: .color(.black))
            }
        }
    }

    private static func drawSkyline(in context: inout GraphicsContext, size: CGSize, horizonY: CGFloat, night: Double) {
        let silhouette = Color(red: 0.17, green: 0.05, blue: 0.27)
        let count = 13
        let step = size.width / CGFloat(count - 1)
        for index in 0..<count {
            let width = step * (0.55 + CGFloat(noise(Double(index) * 1.7)) * 0.4)
            let height = size.width * (0.06 + CGFloat(noise(Double(index) * 4.1 + 2)) * 0.16)
            let rect = CGRect(x: CGFloat(index) * step - width / 2, y: horizonY - height, width: width, height: height)
            context.fill(Path(rect), with: .color(silhouette))

            guard night > 0.2 else { continue }
            // світло у вікнах вночі
            for row in 0..<Int(height / 9) where noise(Double(index * 31 + row)) > 0.55 {
                let window = CGRect(x: rect.minX + width * 0.3, y: rect.minY + 5 + CGFloat(row) * 9,
                                    width: width * 0.4, height: 3)
                context.fill(Path(window), with: .color(Theme.sunYellow.opacity(0.55 * night)))
            }
        }
    }

    private static func drawSea(in context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let sea = CGRect(x: 0, y: horizonY, width: size.width, height: max(size.height - horizonY, 0) + size.width)
        context.fill(Path(sea),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.24, green: 0.10, blue: 0.42),
                                                             Color(red: 0.05, green: 0.03, blue: 0.18)]),
                                           startPoint: CGPoint(x: 0, y: horizonY),
                                           endPoint: CGPoint(x: 0, y: horizonY + size.width * 0.8)))
        // відблиск сонця на воді
        for line in 0..<5 {
            let width = size.width * (0.34 - CGFloat(line) * 0.05)
            let y = horizonY + 8 + CGFloat(line) * 11
            context.fill(Path(roundedRect: CGRect(x: size.width / 2 - width / 2, y: y, width: width, height: 2.5),
                              cornerRadius: 1.25),
                         with: .color(Theme.neonPink.opacity(0.55 - Double(line) * 0.08)))
        }
    }

    // MARK: - Пальми

    private static func drawPalm(in context: inout GraphicsContext, base: CGPoint, height: CGFloat, lean: CGFloat) {
        let silhouette = Color(red: 0.08, green: 0.02, blue: 0.14)
        let top = CGPoint(x: base.x + lean, y: base.y - height)

        var trunk = Path()
        trunk.move(to: base)
        trunk.addQuadCurve(to: top, control: CGPoint(x: base.x + lean * 0.1, y: base.y - height * 0.55))
        context.stroke(trunk, with: .color(silhouette),
                       style: StrokeStyle(lineWidth: max(height * 0.035, 5), lineCap: .round))

        let leafLength = height * 0.42
        let angles: [Double] = [-170, -140, -105, -70, -35, -5]
        for angle in angles {
            let radians = angle * .pi / 180
            let tip = CGPoint(x: top.x + cos(radians) * leafLength,
                              y: top.y + sin(radians) * leafLength * 0.55 + leafLength * 0.35)
            let mid = CGPoint(x: (top.x + tip.x) / 2, y: (top.y + tip.y) / 2)
            var leaf = Path()
            leaf.move(to: top)
            leaf.addQuadCurve(to: tip, control: CGPoint(x: mid.x, y: mid.y - leafLength * 0.30))
            leaf.addQuadCurve(to: top, control: CGPoint(x: mid.x, y: mid.y - leafLength * 0.12))
            context.fill(leaf, with: .color(silhouette))
        }
    }
}
