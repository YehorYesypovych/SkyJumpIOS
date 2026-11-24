import SwiftUI

/// Фон екранів меню в стилі обраної теми: градієнт, відблиск унизу і кілька спокійних силуетів,
/// щоб не заважати тексту.
struct AppBackground: View {
    @Environment(\.worldTheme) private var theme

    var body: some View {
        let palette = theme.palette
        ZStack {
            LinearGradient(colors: palette.background, startPoint: .top, endPoint: .bottom)

            Canvas { context, size in
                drawGlow(in: &context, size: size, color: palette.glow)
                drawDecor(in: &context, size: size, palette: palette)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawGlow(in context: inout GraphicsContext, size: CGSize, color: Color) {
        let width: CGFloat = size.width * 1.5
        let glow = CGRect(x: (size.width - width) / 2, y: size.height * 0.82, width: width, height: size.width * 0.9)
        let opacity: Double = theme.palette.isDark ? 0.5 : 0.25
        context.fill(Path(ellipseIn: glow),
                     with: .radialGradient(Gradient(colors: [color.opacity(opacity), .clear]),
                                           center: CGPoint(x: glow.midX, y: glow.midY),
                                           startRadius: 0, endRadius: width / 2))
    }

    private func drawDecor(in context: inout GraphicsContext, size: CGSize, palette: ThemePalette) {
        switch theme {
        case .neonBeach:
            context.opacity = 0.75
            NeonBeachBackground.drawPalm(in: &context, base: CGPoint(x: size.width * 0.04, y: size.height * 1.02),
                                         height: size.height * 0.30, lean: size.width * 0.08)
            NeonBeachBackground.drawPalm(in: &context, base: CGPoint(x: size.width * 0.97, y: size.height * 1.03),
                                         height: size.height * 0.24, lean: -size.width * 0.09)
        case .reef:
            WorldDecor.drawBubbles(in: &context, size: size, color: .white.opacity(0.18), count: 24, drift: 0)
            WorldDecor.drawSeaweed(in: &context, size: size, color: palette.decor, baseY: size.height)
        case .noirCity:
            WorldDecor.drawMoon(in: &context, center: CGPoint(x: size.width * 0.8, y: size.height * 0.12),
                                radius: size.width * 0.09, color: palette.glow.opacity(0.85))
            WorldDecor.drawSkyline(in: &context, size: size, baseY: size.height, color: palette.decor,
                                   windows: palette.glow.opacity(0.35), scale: 1)
        case .olympus:
            WorldDecor.drawStars(in: &context, size: size, opacity: 0.6, drift: 0)
            WorldDecor.drawClouds(in: &context, size: size, baseY: size.height * 0.95,
                                  color: palette.decor.opacity(0.85))
        case .classic:
            WorldDecor.drawGraphPaper(in: &context, size: size, line: palette.decor.opacity(0.35), offset: 0)
        }
    }
}

extension View {
    /// Картка меню: напівпрозорий фон із тонкою рамкою в кольорах теми.
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }

    /// Фон меню в стилі теми для списків, форм і прокручуваних екранів.
    func appBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(AppBackground())
    }
}

private struct CardStyle: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.worldTheme) private var theme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(theme.palette.card, in: shape)
            .overlay(shape.stroke(theme.palette.cardStroke, lineWidth: 1))
    }
}
