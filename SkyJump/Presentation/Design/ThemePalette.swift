import SwiftUI

/// Кольори теми світу: фон меню, акценти, картки й платформи.
struct ThemePalette {
    let isDark: Bool
    let background: [Color]        // зверху вниз
    let glow: Color                // відблиск унизу фону меню
    let accent: Color
    let accentSecondary: Color
    let card: Color
    let cardStroke: Color
    let decor: Color               // силуети на фоні меню
    let normalPlatform: Color
    let movingPlatform: Color
    let breakablePlatform: Color
    let springPlatform: Color

    func color(for type: PlatformType) -> Color {
        switch type {
        case .normal: return normalPlatform
        case .moving: return movingPlatform
        case .breakable: return breakablePlatform
        case .spring: return springPlatform
        }
    }

    /// Градієнт головної кнопки.
    var buttonGradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary], startPoint: .leading, endPoint: .trailing)
    }
}

private func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
    Color(red: red, green: green, blue: blue)
}

extension WorldTheme {
    var palette: ThemePalette {
        switch self {
        case .neonBeach:
            return ThemePalette(isDark: true,
                                background: [rgb(0.10, 0.04, 0.22), rgb(0.16, 0.06, 0.32), rgb(0.34, 0.10, 0.42)],
                                glow: Theme.neonPink, accent: Theme.neonPink, accentSecondary: Theme.sunsetOrange,
                                card: .white.opacity(0.08), cardStroke: .white.opacity(0.10),
                                decor: rgb(0.08, 0.02, 0.14),
                                normalPlatform: Theme.neonMint, movingPlatform: Theme.electricBlue,
                                breakablePlatform: Theme.sand, springPlatform: Theme.sunYellow)
        case .reef:
            return ThemePalette(isDark: true,
                                background: [rgb(0.02, 0.08, 0.20), rgb(0.03, 0.22, 0.38), rgb(0.04, 0.40, 0.52)],
                                glow: rgb(0.40, 0.90, 1.00), accent: rgb(1.00, 0.45, 0.42), accentSecondary: rgb(1.00, 0.72, 0.30),
                                card: .white.opacity(0.09), cardStroke: .white.opacity(0.12),
                                decor: rgb(0.02, 0.12, 0.18),
                                normalPlatform: rgb(1.00, 0.50, 0.45), movingPlatform: rgb(0.35, 0.85, 1.00),
                                breakablePlatform: rgb(0.95, 0.86, 0.62), springPlatform: rgb(1.00, 0.85, 0.30))
        case .noirCity:
            return ThemePalette(isDark: true,
                                background: [rgb(0.02, 0.02, 0.04), rgb(0.07, 0.07, 0.11), rgb(0.14, 0.14, 0.20)],
                                glow: rgb(1.00, 0.85, 0.35), accent: rgb(1.00, 0.80, 0.20), accentSecondary: rgb(1.00, 0.55, 0.20),
                                card: .white.opacity(0.07), cardStroke: .white.opacity(0.10),
                                decor: rgb(0.01, 0.01, 0.02),
                                normalPlatform: rgb(0.60, 0.65, 0.75), movingPlatform: rgb(1.00, 0.80, 0.20),
                                breakablePlatform: rgb(0.50, 0.44, 0.40), springPlatform: rgb(0.95, 0.25, 0.30))
        case .olympus:
            return ThemePalette(isDark: true,
                                background: [rgb(0.05, 0.07, 0.20), rgb(0.18, 0.24, 0.52), rgb(0.50, 0.60, 0.88)],
                                glow: rgb(1.00, 0.85, 0.45), accent: rgb(0.98, 0.76, 0.26), accentSecondary: rgb(1.00, 0.55, 0.35),
                                card: .white.opacity(0.10), cardStroke: .white.opacity(0.14),
                                decor: rgb(0.92, 0.93, 0.98),
                                normalPlatform: rgb(0.95, 0.93, 0.88), movingPlatform: rgb(0.55, 0.75, 1.00),
                                breakablePlatform: rgb(0.80, 0.68, 0.52), springPlatform: rgb(0.98, 0.76, 0.26))
        case .classic:
            return ThemePalette(isDark: false,
                                background: [rgb(0.99, 0.98, 0.94), rgb(0.98, 0.97, 0.92), rgb(0.97, 0.95, 0.89)],
                                glow: rgb(0.60, 0.80, 1.00), accent: rgb(0.20, 0.58, 0.30), accentSecondary: rgb(0.45, 0.75, 0.30),
                                card: .black.opacity(0.04), cardStroke: .black.opacity(0.08),
                                decor: rgb(0.55, 0.75, 0.95),
                                normalPlatform: rgb(0.40, 0.75, 0.30), movingPlatform: rgb(0.30, 0.55, 0.95),
                                breakablePlatform: rgb(0.62, 0.46, 0.30), springPlatform: rgb(0.95, 0.75, 0.20))
        }
    }
}

// MARK: - Тема в оточенні SwiftUI

private struct WorldThemeKey: EnvironmentKey {
    static let defaultValue: WorldTheme = .neonBeach
}

extension EnvironmentValues {
    /// Поточна тема світу — встановлюється в корені й доступна всім екранам.
    var worldTheme: WorldTheme {
        get { self[WorldThemeKey.self] }
        set { self[WorldThemeKey.self] = newValue }
    }
}

extension View {
    /// Застосовує тему: оточення, акцентний колір і світлу/темну схему системних елементів.
    func worldTheme(_ theme: WorldTheme) -> some View {
        environment(\.worldTheme, theme)
            .tint(theme.palette.accent)
            .preferredColorScheme(theme.palette.isDark ? .dark : .light)
    }
}
