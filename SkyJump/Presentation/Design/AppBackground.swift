import SwiftUI

/// Фон екранів меню: нічне небо над неоновим пляжем — темний градієнт, відблиск заходу сонця
/// і силуети пальм унизу. Той самий настрій, що й у грі, але спокійніший, щоб не заважати тексту.
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.night,
                                    Color(red: 0.16, green: 0.06, blue: 0.32),
                                    Color(red: 0.34, green: 0.10, blue: 0.42)],
                           startPoint: .top, endPoint: .bottom)

            Canvas { context, size in
                // відблиск сонця за горизонтом
                let glow = CGRect(x: size.width * 0.5 - size.width * 0.75, y: size.height * 0.82,
                                  width: size.width * 1.5, height: size.width * 0.9)
                context.fill(Path(ellipseIn: glow),
                             with: .radialGradient(Gradient(colors: [Theme.neonPink.opacity(0.55),
                                                                     Theme.sunsetOrange.opacity(0.15),
                                                                     .clear]),
                                                   center: CGPoint(x: glow.midX, y: glow.midY),
                                                   startRadius: 0, endRadius: glow.width / 2))

                context.opacity = 0.75
                NeonBeachBackground.drawPalm(in: &context,
                                             base: CGPoint(x: size.width * 0.04, y: size.height * 1.02),
                                             height: size.height * 0.30, lean: size.width * 0.08)
                NeonBeachBackground.drawPalm(in: &context,
                                             base: CGPoint(x: size.width * 0.97, y: size.height * 1.03),
                                             height: size.height * 0.24, lean: -size.width * 0.09)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension Theme {
    /// Напівпрозора картка на темному фоні меню.
    static let card = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.10)
}

extension View {
    /// Картка меню: напівпрозорий фон із тонкою рамкою.
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(Theme.card, in: shape)
            .overlay(shape.stroke(Theme.cardStroke, lineWidth: 1))
    }

    /// Темний фон меню для списків, форм і прокручуваних екранів.
    func appBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(AppBackground())
    }
}
