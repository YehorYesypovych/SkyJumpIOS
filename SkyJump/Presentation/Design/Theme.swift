import SwiftUI

/// Візуальний стиль застосунку: неоновий пляж на заході сонця — мінімалістично, кілька кольорів, багато повітря.
enum Theme {
    // MARK: Кольори

    static let night = Color(red: 0.10, green: 0.04, blue: 0.22)
    static let dusk = Color(red: 0.36, green: 0.12, blue: 0.48)
    static let neonPink = Color(red: 1.00, green: 0.29, blue: 0.60)
    static let sunsetOrange = Color(red: 1.00, green: 0.58, blue: 0.27)
    static let sunYellow = Color(red: 1.00, green: 0.86, blue: 0.36)
    static let neonMint = Color(red: 0.16, green: 0.89, blue: 0.76)
    static let electricBlue = Color(red: 0.30, green: 0.58, blue: 1.00)
    static let sand = Color(red: 0.96, green: 0.80, blue: 0.58)

    /// Основний акцент кнопок і посилань.
    static let accent = neonPink

    // MARK: Градієнти

    static let sunset = LinearGradient(colors: [dusk, neonPink, sunsetOrange],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)

    static let playButton = LinearGradient(colors: [neonPink, sunsetOrange],
                                           startPoint: .leading, endPoint: .trailing)

    static func gradient(for difficulty: LevelDifficulty) -> LinearGradient {
        switch difficulty {
        case .easy:
            return LinearGradient(colors: [neonMint, electricBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .normal:
            return LinearGradient(colors: [neonPink, sunsetOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .hard:
            return LinearGradient(colors: [dusk, neonPink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: Позначки

    static func emoji(for difficulty: LevelDifficulty) -> String {
        switch difficulty {
        case .easy: return "🌴"
        case .normal: return "🌆"
        case .hard: return "🔥"
        }
    }

    static func color(for type: PlatformType) -> Color {
        switch type {
        case .normal: return neonMint
        case .moving: return electricBlue
        case .breakable: return sand
        case .spring: return sunYellow
        }
    }
}

/// Кнопка з градієнтом теми на всю ширину — головна дія екрана.
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GradientButtonBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

/// Тіло кнопки окремим виглядом, щоб читати тему з оточення.
private struct GradientButtonBody<Label: View>: View {
    let label: Label
    let isPressed: Bool
    @Environment(\.worldTheme) private var theme

    var body: some View {
        let palette = theme.palette
        label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(palette.buttonGradient, in: Capsule())
            .shadow(color: palette.accent.opacity(0.35), radius: 10, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1)
            .opacity(isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.15), value: isPressed)
    }
}

extension ButtonStyle where Self == GradientButtonStyle {
    static var gradient: GradientButtonStyle { GradientButtonStyle() }
}
