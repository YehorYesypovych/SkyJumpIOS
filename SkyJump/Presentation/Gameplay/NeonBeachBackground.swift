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
        let climbOnScreen: CGFloat = CGFloat(climb) * scale
        let horizonY: CGFloat = size.height * 0.70 + climbOnScreen * 0.35
        guard horizonY < size.height + size.width else { return }

        // сонце видно, лише поки горизонт на екрані; приховане — не малюємо (шар зі змішуванням дорогий)
        if horizonY < size.height + size.width * 0.3 {
            drawSun(in: &context, size: size, horizonY: horizonY, night: night)
        }
        drawSkyline(in: &context, size: size, horizonY: horizonY, night: night)
        drawSea(in: &context, size: size, horizonY: horizonY)

        let palmsBase: CGFloat = size.height * 1.03 + climbOnScreen * 0.6
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

    /// Зоря: відносні координати 0…1 і радіус.
    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat

        init(index: Int) {
            let seed = Double(index)
            x = CGFloat(NeonBeachBackground.noise(seed + 0.5))
            y = CGFloat(NeonBeachBackground.noise(seed * 7.31 + 3))
            radius = NeonBeachBackground.noise(seed * 3.7) > 0.8 ? 1.8 : 1.1
        }
    }

    /// Будинок: відносні ширина й висота та поверхи, де вночі світяться вікна.
    private struct Building {
        let width: CGFloat
        let height: CGFloat
        let litRows: [Int]

        init(index: Int) {
            let seed = Double(index)
            let widthNoise = CGFloat(NeonBeachBackground.noise(seed * 1.7))
            let heightNoise = CGFloat(NeonBeachBackground.noise(seed * 4.1 + 2))
            width = 0.55 + widthNoise * 0.4
            height = 0.06 + heightNoise * 0.16
            litRows = (0..<40).filter { row in NeonBeachBackground.noise(Double(index * 31 + row)) > 0.55 }
        }
    }

    /// Зорі й будинки рахуються один раз, а не щокадру.
    private static let stars: [Star] = (0..<70).map { Star(index: $0) }
    private static let buildings: [Building] = (0..<13).map { Building(index: $0) }

    private static func drawStars(in context: inout GraphicsContext, size: CGSize,
                                  night: Double, climb: Double, scale: CGFloat) {
        guard night > 0.05 else { return }
        let drift: CGFloat = CGFloat(climb) * scale * 0.05
        // усі зорі — один шлях і одна заливка замість 70 окремих
        var path = Path()
        for star in stars {
            let rawY: CGFloat = star.y * size.height + drift
            let y = rawY.truncatingRemainder(dividingBy: size.height)
            let diameter: CGFloat = star.radius * 2
            path.addEllipse(in: CGRect(x: star.x * size.width, y: y, width: diameter, height: diameter))
        }
        context.fill(path, with: .color(.white.opacity(0.85 * night)))
    }

    // MARK: - Сонце, місто, море

    private static func drawSun(in context: inout GraphicsContext, size: CGSize, horizonY: CGFloat, night: Double) {
        let radius: CGFloat = size.width * 0.26
        let center = CGPoint(x: size.width * 0.5, y: horizonY - radius * 0.35)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        context.drawLayer { layer in
            layer.opacity = 1.0 - night * 0.85
            layer.fill(Path(ellipseIn: rect),
                       with: .linearGradient(Gradient(colors: [Theme.sunYellow, Theme.neonPink]),
                                             startPoint: CGPoint(x: center.x, y: rect.minY),
                                             endPoint: CGPoint(x: center.x, y: rect.maxY)))
            // смуги на нижній половині сонця — класика synthwave
            layer.blendMode = .destinationOut
            for stripe in 0..<6 {
                let index = CGFloat(stripe)
                let offset: CGFloat = radius * (0.05 + index * 0.16)
                let y = center.y + offset
                let height: CGFloat = 2 + index * 1.6
                layer.fill(Path(CGRect(x: rect.minX, y: y, width: rect.width, height: height)), with: .color(.black))
            }
        }
    }

    private static func drawSkyline(in context: inout GraphicsContext, size: CGSize, horizonY: CGFloat, night: Double) {
        let silhouette = Color(red: 0.17, green: 0.05, blue: 0.27)
        let step = size.width / CGFloat(buildings.count - 1)
        var city = Path()
        var windows = Path()
        for (index, building) in buildings.enumerated() {
            let width: CGFloat = step * building.width
            let height: CGFloat = size.width * building.height
            let x: CGFloat = CGFloat(index) * step - width / 2
            let rect = CGRect(x: x, y: horizonY - height, width: width, height: height)
            city.addRect(rect)

            guard night > 0.2 else { continue }
            // світло у вікнах вночі
            let floors = Int(height / 9)
            for row in building.litRows where row < floors {
                let windowY: CGFloat = rect.minY + 5 + CGFloat(row) * 9
                windows.addRect(CGRect(x: rect.minX + width * 0.3, y: windowY, width: width * 0.4, height: 3))
            }
        }
        context.fill(city, with: .color(silhouette))
        if night > 0.2 {
            context.fill(windows, with: .color(Theme.sunYellow.opacity(0.55 * night)))
        }
    }

    private static func drawSea(in context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let seaHeight: CGFloat = max(size.height - horizonY, 0) + size.width
        let sea = CGRect(x: 0, y: horizonY, width: size.width, height: seaHeight)
        context.fill(Path(sea),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.24, green: 0.10, blue: 0.42),
                                                             Color(red: 0.05, green: 0.03, blue: 0.18)]),
                                           startPoint: CGPoint(x: 0, y: horizonY),
                                           endPoint: CGPoint(x: 0, y: horizonY + size.width * 0.8)))
        // відблиск сонця на воді (лише коли вода на екрані)
        guard horizonY < size.height else { return }
        for line in 0..<5 {
            let index = CGFloat(line)
            let width: CGFloat = size.width * (0.34 - index * 0.05)
            let y: CGFloat = horizonY + 8 + index * 11
            let rect = CGRect(x: (size.width - width) / 2, y: y, width: width, height: 2.5)
            let opacity: Double = 0.55 - Double(line) * 0.08
            context.fill(Path(roundedRect: rect, cornerRadius: 1.25), with: .color(Theme.neonPink.opacity(opacity)))
        }
    }

    // MARK: - Пальми

    /// Напрямки листків пальми (косинус і синус кута), пораховані один раз.
    private static let leafDirections: [CGVector] = [-170.0, -140, -105, -70, -35, -5].map { (degrees: Double) -> CGVector in
        let radians = degrees * Double.pi / 180
        return CGVector(dx: CGFloat(cos(radians)), dy: CGFloat(sin(radians)))
    }

    static func drawPalm(in context: inout GraphicsContext, base: CGPoint, height: CGFloat, lean: CGFloat) {
        let silhouette = Color(red: 0.08, green: 0.02, blue: 0.14)
        let top = CGPoint(x: base.x + lean, y: base.y - height)

        var trunk = Path()
        trunk.move(to: base)
        trunk.addQuadCurve(to: top, control: CGPoint(x: base.x + lean * 0.1, y: base.y - height * 0.55))
        context.stroke(trunk, with: .color(silhouette),
                       style: StrokeStyle(lineWidth: max(height * 0.035, 5), lineCap: .round))

        let leafLength: CGFloat = height * 0.42
        var leaves = Path()
        for direction in leafDirections {
            let tipX: CGFloat = top.x + direction.dx * leafLength
            let tipY: CGFloat = top.y + direction.dy * leafLength * 0.55 + leafLength * 0.35
            let midX: CGFloat = (top.x + tipX) / 2
            let midY: CGFloat = (top.y + tipY) / 2
            leaves.move(to: top)
            leaves.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: midX, y: midY - leafLength * 0.30))
            leaves.addQuadCurve(to: top, control: CGPoint(x: midX, y: midY - leafLength * 0.12))
        }
        context.fill(leaves, with: .color(silhouette))
    }
}
