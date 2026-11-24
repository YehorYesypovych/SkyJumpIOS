import SwiftUI

/// Спільні малюнки для фонів тем (меню і гра): бульбашки, водорості, місяць, місто, хмари,
/// зорі, колони, планети, зошит. Випадкові розміри й позиції пораховані один раз.
enum WorldDecor {

    // MARK: - Псевдовипадкові дані

    static func noise(_ seed: Double) -> Double {
        let value = sin(seed * 12.9898) * 43_758.5453
        return value - value.rounded(.down)
    }

    /// Точка з відносними координатами 0…1 і розміром 0…1.
    struct Dot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat

        init(index: Int, salt: Double) {
            let seed = Double(index) + salt
            x = CGFloat(WorldDecor.noise(seed + 0.5))
            y = CGFloat(WorldDecor.noise(seed * 7.31 + 3))
            size = CGFloat(WorldDecor.noise(seed * 3.7 + 1))
        }
    }

    private static let starDots: [Dot] = (0..<80).map { Dot(index: $0, salt: 0) }
    private static let bubbleDots: [Dot] = (0..<40).map { Dot(index: $0, salt: 100) }
    private static let cloudDots: [Dot] = (0..<9).map { Dot(index: $0, salt: 200) }
    private static let rainDots: [Dot] = (0..<60).map { Dot(index: $0, salt: 300) }
    private static let skylineDots: [Dot] = (0..<14).map { Dot(index: $0, salt: 400) }

    /// Зсув по вертикалі з «прокручуванням» по колу в межах висоти екрана.
    private static func wrapped(_ y: CGFloat, drift: CGFloat, height: CGFloat) -> CGFloat {
        let shifted: CGFloat = y * height + drift
        let remainder = shifted.truncatingRemainder(dividingBy: height)
        return remainder < 0 ? remainder + height : remainder
    }

    // MARK: - Небо

    static func drawStars(in context: inout GraphicsContext, size: CGSize, opacity: Double, drift: CGFloat) {
        guard opacity > 0.02 else { return }
        var path = Path()
        for dot in starDots {
            let diameter: CGFloat = dot.size > 0.8 ? 3.4 : 2
            let y = wrapped(dot.y, drift: drift, height: size.height)
            path.addEllipse(in: CGRect(x: dot.x * size.width, y: y, width: diameter, height: diameter))
        }
        context.fill(path, with: .color(.white.opacity(0.85 * opacity)))
    }

    static func drawMoon(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        let halo = CGRect(x: center.x - radius * 2.2, y: center.y - radius * 2.2, width: radius * 4.4, height: radius * 4.4)
        context.fill(Path(ellipseIn: halo),
                     with: .radialGradient(Gradient(colors: [color.opacity(0.35), .clear]),
                                           center: center, startRadius: radius, endRadius: radius * 2.2))
        let disk = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: disk), with: .color(color))
    }

    static func drawClouds(in context: inout GraphicsContext, size: CGSize, baseY: CGFloat, color: Color) {
        var path = Path()
        for (index, dot) in cloudDots.enumerated() {
            let width: CGFloat = size.width * (0.35 + dot.size * 0.3)
            let height: CGFloat = width * 0.32
            let x: CGFloat = CGFloat(index) / CGFloat(cloudDots.count - 1) * size.width - width / 2
            let y: CGFloat = baseY - height * (0.4 + dot.y * 0.8)
            path.addEllipse(in: CGRect(x: x, y: y, width: width, height: height))
            path.addEllipse(in: CGRect(x: x + width * 0.2, y: y - height * 0.45, width: width * 0.55, height: height))
        }
        context.fill(path, with: .color(color))
    }

    static func drawPlanets(in context: inout GraphicsContext, size: CGSize, drift: CGFloat, opacity: Double) {
        guard opacity > 0.02 else { return }
        context.drawLayer { layer in
            layer.opacity = opacity
            let ringed = CGPoint(x: size.width * 0.78, y: wrapped(0.2, drift: drift * 0.5, height: size.height))
            let radius: CGFloat = size.width * 0.09
            layer.fill(Path(ellipseIn: CGRect(x: ringed.x - radius, y: ringed.y - radius, width: radius * 2, height: radius * 2)),
                       with: .linearGradient(Gradient(colors: [Color(red: 0.98, green: 0.75, blue: 0.45),
                                                               Color(red: 0.85, green: 0.45, blue: 0.35)]),
                                             startPoint: CGPoint(x: ringed.x, y: ringed.y - radius),
                                             endPoint: CGPoint(x: ringed.x, y: ringed.y + radius)))
            let ring = CGRect(x: ringed.x - radius * 1.8, y: ringed.y - radius * 0.35, width: radius * 3.6, height: radius * 0.7)
            layer.stroke(Path(ellipseIn: ring), with: .color(.white.opacity(0.7)), lineWidth: 2)

            let small = CGPoint(x: size.width * 0.18, y: wrapped(0.65, drift: drift * 0.7, height: size.height))
            let smallRadius: CGFloat = size.width * 0.045
            layer.fill(Path(ellipseIn: CGRect(x: small.x - smallRadius, y: small.y - smallRadius,
                                              width: smallRadius * 2, height: smallRadius * 2)),
                       with: .color(Color(red: 0.45, green: 0.75, blue: 1.0)))
        }
    }

    // MARK: - Вода

    static func drawBubbles(in context: inout GraphicsContext, size: CGSize, color: Color, count: Int, drift: CGFloat) {
        var path = Path()
        for dot in bubbleDots.prefix(count) {
            let diameter: CGFloat = 4 + dot.size * 12
            let y = wrapped(dot.y, drift: -drift, height: size.height)
            path.addEllipse(in: CGRect(x: dot.x * size.width, y: y, width: diameter, height: diameter))
        }
        context.stroke(path, with: .color(color), lineWidth: 1.5)
    }

    static func drawSeaweed(in context: inout GraphicsContext, size: CGSize, color: Color, baseY: CGFloat) {
        var path = Path()
        let positions: [CGFloat] = [0.05, 0.12, 0.85, 0.93]
        for (index, position) in positions.enumerated() {
            let x: CGFloat = size.width * position
            let height: CGFloat = size.height * (0.18 + CGFloat(index % 2) * 0.08)
            path.move(to: CGPoint(x: x, y: baseY))
            path.addCurve(to: CGPoint(x: x + 10, y: baseY - height),
                          control1: CGPoint(x: x - 22, y: baseY - height * 0.35),
                          control2: CGPoint(x: x + 26, y: baseY - height * 0.7))
        }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 9, lineCap: .round))
    }

    static func drawLightRays(in context: inout GraphicsContext, size: CGSize, opacity: Double) {
        guard opacity > 0.02 else { return }
        var path = Path()
        for index in 0..<5 {
            let x: CGFloat = size.width * (0.1 + CGFloat(index) * 0.2)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + size.width * 0.08, y: 0))
            path.addLine(to: CGPoint(x: x - size.width * 0.05, y: size.height))
            path.addLine(to: CGPoint(x: x - size.width * 0.15, y: size.height))
            path.closeSubpath()
        }
        context.fill(path, with: .color(.white.opacity(0.10 * opacity)))
    }

    static func drawFish(in context: inout GraphicsContext, size: CGSize, drift: CGFloat, color: Color) {
        var path = Path()
        for index in 0..<4 {
            let dot = bubbleDots[index]
            let x: CGFloat = dot.x * size.width
            let y = wrapped(dot.y, drift: drift * 0.4, height: size.height)
            let length: CGFloat = 18 + dot.size * 16
            path.addEllipse(in: CGRect(x: x, y: y, width: length, height: length * 0.45))
            path.move(to: CGPoint(x: x + length, y: y + length * 0.22))
            path.addLine(to: CGPoint(x: x + length * 1.35, y: y))
            path.addLine(to: CGPoint(x: x + length * 1.35, y: y + length * 0.45))
            path.closeSubpath()
        }
        context.fill(path, with: .color(color))
    }

    // MARK: - Місто

    static func drawSkyline(in context: inout GraphicsContext, size: CGSize, baseY: CGFloat,
                            color: Color, windows: Color, scale: CGFloat) {
        var city = Path()
        var lights = Path()
        let step: CGFloat = size.width / CGFloat(skylineDots.count - 1)
        for (index, dot) in skylineDots.enumerated() {
            let width: CGFloat = step * (0.6 + dot.x * 0.4)
            let height: CGFloat = size.width * (0.12 + dot.size * 0.35) * scale
            let rect = CGRect(x: CGFloat(index) * step - width / 2, y: baseY - height, width: width, height: height)
            city.addRect(rect)
            let floors = Int(height / 12)
            for floor in 0..<floors where WorldDecor.noise(Double(index * 37 + floor)) > 0.6 {
                let y: CGFloat = rect.minY + 6 + CGFloat(floor) * 12
                lights.addRect(CGRect(x: rect.minX + width * 0.25, y: y, width: width * 0.5, height: 4))
            }
        }
        context.fill(city, with: .color(color))
        context.fill(lights, with: .color(windows))
    }

    static func drawRain(in context: inout GraphicsContext, size: CGSize, drift: CGFloat, opacity: Double) {
        guard opacity > 0.02 else { return }
        var path = Path()
        for dot in rainDots {
            let x: CGFloat = dot.x * size.width
            let y = wrapped(dot.y, drift: drift * 1.5, height: size.height)
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 4, y: y + 14))
        }
        context.stroke(path, with: .color(.white.opacity(0.25 * opacity)), lineWidth: 1)
    }

    static func drawSearchlights(in context: inout GraphicsContext, size: CGSize, color: Color, opacity: Double) {
        guard opacity > 0.02 else { return }
        var path = Path()
        let sources: [(x: CGFloat, angle: CGFloat)] = [(0.2, -0.35), (0.75, 0.3)]
        for source in sources {
            let base = CGPoint(x: size.width * source.x, y: size.height)
            let topX: CGFloat = base.x + size.height * source.angle
            path.move(to: base)
            path.addLine(to: CGPoint(x: topX - 40, y: 0))
            path.addLine(to: CGPoint(x: topX + 40, y: 0))
            path.closeSubpath()
        }
        context.fill(path, with: .linearGradient(Gradient(colors: [color.opacity(0.0), color.opacity(0.18 * opacity)]),
                                                 startPoint: CGPoint(x: 0, y: 0),
                                                 endPoint: CGPoint(x: 0, y: size.height)))
    }

    // MARK: - Земля й Олімп

    static func drawHills(in context: inout GraphicsContext, size: CGSize, baseY: CGFloat, near: Color, far: Color) {
        var farPath = Path()
        farPath.move(to: CGPoint(x: 0, y: baseY))
        farPath.addCurve(to: CGPoint(x: size.width, y: baseY - size.height * 0.05),
                         control1: CGPoint(x: size.width * 0.3, y: baseY - size.height * 0.25),
                         control2: CGPoint(x: size.width * 0.6, y: baseY - size.height * 0.05))
        farPath.addLine(to: CGPoint(x: size.width, y: baseY + size.height))
        farPath.addLine(to: CGPoint(x: 0, y: baseY + size.height))
        farPath.closeSubpath()
        context.fill(farPath, with: .color(far))

        var nearPath = Path()
        nearPath.move(to: CGPoint(x: 0, y: baseY + size.height * 0.08))
        nearPath.addCurve(to: CGPoint(x: size.width, y: baseY + size.height * 0.04),
                          control1: CGPoint(x: size.width * 0.4, y: baseY - size.height * 0.08),
                          control2: CGPoint(x: size.width * 0.7, y: baseY + size.height * 0.1))
        nearPath.addLine(to: CGPoint(x: size.width, y: baseY + size.height))
        nearPath.addLine(to: CGPoint(x: 0, y: baseY + size.height))
        nearPath.closeSubpath()
        context.fill(nearPath, with: .color(near))
    }

    static func drawTemple(in context: inout GraphicsContext, size: CGSize, baseY: CGFloat, color: Color) {
        let width: CGFloat = size.width * 0.62
        let left: CGFloat = (size.width - width) / 2
        let columnHeight: CGFloat = width * 0.42
        var path = Path()
        // сходинки
        path.addRect(CGRect(x: left - 10, y: baseY - 10, width: width + 20, height: 10))
        path.addRect(CGRect(x: left, y: baseY - 18, width: width, height: 8))
        // колони
        let columns = 6
        let columnWidth: CGFloat = width / CGFloat(columns * 2 - 1)
        for index in 0..<columns {
            let x: CGFloat = left + CGFloat(index * 2) * columnWidth
            path.addRect(CGRect(x: x, y: baseY - 18 - columnHeight, width: columnWidth, height: columnHeight))
        }
        // дах-фронтон
        let roofBase: CGFloat = baseY - 18 - columnHeight
        path.addRect(CGRect(x: left - 6, y: roofBase - 10, width: width + 12, height: 10))
        path.move(to: CGPoint(x: left - 10, y: roofBase - 10))
        path.addLine(to: CGPoint(x: size.width / 2, y: roofBase - 10 - width * 0.18))
        path.addLine(to: CGPoint(x: left + width + 10, y: roofBase - 10))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    // MARK: - Класика

    static func drawGraphPaper(in context: inout GraphicsContext, size: CGSize, line: Color, offset: CGFloat) {
        let cell: CGFloat = 22
        var grid = Path()
        var x: CGFloat = 0
        while x <= size.width {
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: size.height))
            x += cell
        }
        var y: CGFloat = offset.truncatingRemainder(dividingBy: cell)
        if y < 0 { y += cell }
        while y <= size.height {
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
            y += cell
        }
        context.stroke(grid, with: .color(line), lineWidth: 0.7)
        // червоне поле зошита
        var margin = Path()
        margin.move(to: CGPoint(x: 34, y: 0))
        margin.addLine(to: CGPoint(x: 34, y: size.height))
        context.stroke(margin, with: .color(Color(red: 0.92, green: 0.35, blue: 0.35).opacity(0.6)), lineWidth: 1.2)
    }
}
