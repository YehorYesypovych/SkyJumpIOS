import SwiftUI

/// Фон гри для кожної теми. Світ змінюється з висотою: етапи теми плавно переходять один в одний,
/// а наземні декорації «опускаються» за екран — виходить візуальне проходження знизу вгору.
enum WorldRenderer {

    /// climb — висота найвищої точки гравця, scale — пікселів на одиницю світу.
    static func drawBackground(theme: WorldTheme, in context: inout GraphicsContext,
                               size: CGSize, cameraBottom: Double, scale: CGFloat) {
        let climb = max(cameraBottom + GameplayViewModel.cameraOffset, 0)
        let blend = StageBlend(stages: theme.stages, climb: climb)
        let climbOnScreen: CGFloat = CGFloat(climb) * scale

        switch theme {
        case .neonBeach:
            NeonBeachBackground.draw(in: &context, size: size, cameraBottom: cameraBottom, scale: scale)
        case .reef:
            drawReef(in: &context, size: size, blend: blend, climbOnScreen: climbOnScreen)
        case .noirCity:
            drawNoir(in: &context, size: size, blend: blend, climbOnScreen: climbOnScreen)
        case .olympus:
            drawOlympus(in: &context, size: size, blend: blend, climbOnScreen: climbOnScreen)
        case .classic:
            fillSky(in: &context, size: size, colors: [RGB(0.99, 0.98, 0.94), RGB(0.98, 0.97, 0.92), RGB(0.97, 0.95, 0.89)])
            WorldDecor.drawGraphPaper(in: &context, size: size,
                                      line: Color(red: 0.55, green: 0.75, blue: 0.95).opacity(0.45),
                                      offset: climbOnScreen)
        }
    }

    // MARK: - Етапи

    /// Який етап зараз і наскільки близько наступний (0 — середина етапу, 1 — вже наступний).
    struct StageBlend {
        let index: Int
        let next: Double            // 0…1 — частка наступного етапу в переході
        static let transition = 700.0

        init(stages: [WorldStage], climb: Double) {
            let current = stages.lastIndex { climb >= $0.startHeight } ?? 0
            index = current
            if current + 1 < stages.count {
                let nextStart = stages[current + 1].startHeight
                let progress = (climb - (nextStart - Self.transition)) / Self.transition
                next = min(max(progress, 0), 1)
            } else {
                next = 0
            }
        }

        /// Наскільки видно етап з номером stage: 1 — повністю, 0 — зовсім.
        func weight(of stage: Int) -> Double {
            if stage == index { return 1 - next }
            if stage == index + 1 { return next }
            return 0
        }
    }

    /// Колір у RGB, який можна змішувати.
    struct RGB {
        let r: Double
        let g: Double
        let b: Double

        init(_ r: Double, _ g: Double, _ b: Double) {
            self.r = r
            self.g = g
            self.b = b
        }

        func mixed(with other: RGB, _ t: Double) -> RGB {
            RGB(r + (other.r - r) * t, g + (other.g - g) * t, b + (other.b - b) * t)
        }

        var color: Color { Color(red: r, green: g, blue: b) }
    }

    /// Небо поточного етапу, змішане з наступним.
    private static func skyColors(_ skies: [[RGB]], blend: StageBlend) -> [RGB] {
        let current = skies[min(blend.index, skies.count - 1)]
        let next = skies[min(blend.index + 1, skies.count - 1)]
        return zip(current, next).map { pair in pair.0.mixed(with: pair.1, blend.next) }
    }

    private static func fillSky(in context: inout GraphicsContext, size: CGSize, colors: [RGB]) {
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: colors.map(\.color)),
                                           startPoint: .zero,
                                           endPoint: CGPoint(x: 0, y: size.height)))
    }

    // MARK: - Риф: дно → відкрита вода → поверхня → небо

    private static let reefSkies: [[RGB]] = [
        [RGB(0.02, 0.18, 0.32), RGB(0.03, 0.30, 0.42), RGB(0.10, 0.42, 0.48)],
        [RGB(0.02, 0.28, 0.52), RGB(0.04, 0.42, 0.66), RGB(0.05, 0.36, 0.58)],
        [RGB(0.30, 0.75, 0.90), RGB(0.15, 0.62, 0.84), RGB(0.06, 0.48, 0.72)],
        [RGB(0.45, 0.72, 1.00), RGB(0.65, 0.85, 1.00), RGB(0.95, 0.90, 0.80)]
    ]

    private static func drawReef(in context: inout GraphicsContext, size: CGSize,
                                 blend: StageBlend, climbOnScreen: CGFloat) {
        fillSky(in: &context, size: size, colors: skyColors(reefSkies, blend: blend))

        let underwater = 1 - blend.weight(of: 3)
        WorldDecor.drawLightRays(in: &context, size: size, opacity: blend.weight(of: 2))
        if blend.weight(of: 1) + blend.weight(of: 2) > 0.05 {
            WorldDecor.drawFish(in: &context, size: size, drift: climbOnScreen,
                                color: Color(red: 0.02, green: 0.12, blue: 0.22).opacity(0.55))
        }
        if underwater > 0.05 {
            WorldDecor.drawBubbles(in: &context, size: size, color: .white.opacity(0.25 * underwater),
                                   count: 30, drift: climbOnScreen * 0.6)
        }
        if blend.weight(of: 3) > 0.05 {
            WorldDecor.drawClouds(in: &context, size: size, baseY: size.height * 0.35,
                                  color: .white.opacity(0.8 * blend.weight(of: 3)))
        }

        // дно з піском і водоростями йде вниз, коли гравець піднімається
        let floorY: CGFloat = size.height * 0.92 + climbOnScreen * 0.6
        if floorY < size.height + 200 {
            var sand = Path()
            sand.move(to: CGPoint(x: 0, y: floorY))
            sand.addQuadCurve(to: CGPoint(x: size.width, y: floorY - 20),
                              control: CGPoint(x: size.width * 0.5, y: floorY - 50))
            sand.addLine(to: CGPoint(x: size.width, y: floorY + size.height))
            sand.addLine(to: CGPoint(x: 0, y: floorY + size.height))
            sand.closeSubpath()
            context.fill(sand, with: .color(Color(red: 0.85, green: 0.76, blue: 0.55)))
            WorldDecor.drawSeaweed(in: &context, size: size,
                                   color: Color(red: 0.05, green: 0.45, blue: 0.35), baseY: floorY)
        }
    }

    // MARK: - Нуар-місто: вулиця → хмарочоси → дахи → над містом

    private static let noirSkies: [[RGB]] = [
        [RGB(0.05, 0.05, 0.08), RGB(0.10, 0.09, 0.13), RGB(0.22, 0.17, 0.14)],
        [RGB(0.03, 0.03, 0.06), RGB(0.07, 0.07, 0.11), RGB(0.12, 0.12, 0.18)],
        [RGB(0.02, 0.02, 0.05), RGB(0.06, 0.06, 0.12), RGB(0.10, 0.10, 0.20)],
        [RGB(0.01, 0.01, 0.04), RGB(0.04, 0.05, 0.12), RGB(0.08, 0.09, 0.20)]
    ]

    private static func drawNoir(in context: inout GraphicsContext, size: CGSize,
                                 blend: StageBlend, climbOnScreen: CGFloat) {
        fillSky(in: &context, size: size, colors: skyColors(noirSkies, blend: blend))
        let moonColor = Color(red: 1.0, green: 0.88, blue: 0.55)

        WorldDecor.drawStars(in: &context, size: size, opacity: blend.weight(of: 3), drift: climbOnScreen * 0.05)
        WorldDecor.drawMoon(in: &context, center: CGPoint(x: size.width * 0.78, y: size.height * 0.16),
                            radius: size.width * 0.08, color: moonColor)
        WorldDecor.drawSearchlights(in: &context, size: size, color: moonColor,
                                    opacity: blend.weight(of: 2) + blend.weight(of: 1) * 0.5)
        WorldDecor.drawRain(in: &context, size: size, drift: climbOnScreen,
                            opacity: blend.weight(of: 1) + blend.weight(of: 0) * 0.6)

        // дальні хмарочоси рухаються повільніше за ближні (паралакс)
        let farBase: CGFloat = size.height * 1.05 + climbOnScreen * 0.25
        if farBase - size.width * 0.5 < size.height {
            WorldDecor.drawSkyline(in: &context, size: size, baseY: farBase,
                                   color: Color(red: 0.10, green: 0.10, blue: 0.15),
                                   windows: moonColor.opacity(0.25), scale: 2.2)
        }
        let nearBase: CGFloat = size.height * 1.02 + climbOnScreen * 0.55
        if nearBase - size.width * 0.3 < size.height {
            WorldDecor.drawSkyline(in: &context, size: size, baseY: nearBase,
                                   color: Color(red: 0.03, green: 0.03, blue: 0.05),
                                   windows: moonColor.opacity(0.45), scale: 1.2)
        }
    }

    // MARK: - Олімп: земля → хмари → Олімп → космос

    private static let olympusSkies: [[RGB]] = [
        [RGB(0.35, 0.62, 0.95), RGB(0.55, 0.78, 1.00), RGB(0.85, 0.93, 1.00)],
        [RGB(0.55, 0.70, 0.95), RGB(0.78, 0.86, 1.00), RGB(0.95, 0.96, 1.00)],
        [RGB(0.95, 0.70, 0.40), RGB(1.00, 0.85, 0.55), RGB(1.00, 0.95, 0.80)],
        [RGB(0.01, 0.01, 0.06), RGB(0.05, 0.04, 0.18), RGB(0.15, 0.10, 0.35)]
    ]

    private static func drawOlympus(in context: inout GraphicsContext, size: CGSize,
                                    blend: StageBlend, climbOnScreen: CGFloat) {
        fillSky(in: &context, size: size, colors: skyColors(olympusSkies, blend: blend))

        let space = blend.weight(of: 3)
        WorldDecor.drawStars(in: &context, size: size, opacity: space, drift: climbOnScreen * 0.05)
        WorldDecor.drawPlanets(in: &context, size: size, drift: climbOnScreen * 0.1, opacity: space)

        // хмари пропливають униз з паралаксом; у космосі їх уже не видно
        let clouds = blend.weight(of: 1) + blend.weight(of: 2) + blend.weight(of: 0) * 0.5
        if clouds > 0.05 {
            let drift = climbOnScreen * 0.3
            let cloudY: CGFloat = (size.height * 0.4 + drift).truncatingRemainder(dividingBy: size.height * 1.4)
            WorldDecor.drawClouds(in: &context, size: size, baseY: cloudY,
                                  color: .white.opacity(0.75 * clouds))
        }

        // храм з'являється на етапі «Олімп» і так само йде вниз, коли летиш далі
        let temple = blend.weight(of: 2)
        if temple > 0.05 {
            context.drawLayer { layer in
                layer.opacity = temple
                WorldDecor.drawClouds(in: &layer, size: size, baseY: size.height * 0.98, color: .white.opacity(0.95))
                WorldDecor.drawTemple(in: &layer, size: size, baseY: size.height * 0.9,
                                      color: Color(red: 0.97, green: 0.95, blue: 0.90))
            }
        }

        // земля з пагорбами — лише на старті
        let groundY: CGFloat = size.height * 0.88 + climbOnScreen * 0.6
        if groundY < size.height + 100 {
            WorldDecor.drawHills(in: &context, size: size, baseY: groundY,
                                 near: Color(red: 0.30, green: 0.68, blue: 0.32),
                                 far: Color(red: 0.45, green: 0.78, blue: 0.48))
        }
    }
}
