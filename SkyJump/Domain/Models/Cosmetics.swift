import Foundation

/// Тема світу: від неї залежать меню, фон гри, кольори платформ і те,
/// як змінюється світ під час підйому (етапи «проходження»).
enum WorldTheme: String, CaseIterable, Identifiable, Codable {
    case neonBeach
    case reef
    case noirCity
    case olympus
    case classic

    var id: Self { self }

    var title: String {
        switch self {
        case .neonBeach: return "Неоновий пляж"
        case .reef: return "Риф"
        case .noirCity: return "Нуар-місто"
        case .olympus: return "Олімп"
        case .classic: return "Класика"
        }
    }

    var emoji: String {
        switch self {
        case .neonBeach: return "🌴"
        case .reef: return "🐠"
        case .noirCity: return "🌃"
        case .olympus: return "⚡️"
        case .classic: return "📝"
        }
    }

    /// Етапи підйому: з якої висоти починається етап і як він називається.
    var stages: [WorldStage] {
        switch self {
        case .neonBeach:
            return [WorldStage(title: "Пляж", startHeight: 0),
                    WorldStage(title: "Нічне місто", startHeight: 1_500),
                    WorldStage(title: "Зорі", startHeight: 4_000)]
        case .reef:
            return [WorldStage(title: "Морське дно", startHeight: 0),
                    WorldStage(title: "Відкрита вода", startHeight: 1_500),
                    WorldStage(title: "Поверхня", startHeight: 3_500),
                    WorldStage(title: "Небо над морем", startHeight: 6_000)]
        case .noirCity:
            return [WorldStage(title: "Вулиця", startHeight: 0),
                    WorldStage(title: "Хмарочоси", startHeight: 1_500),
                    WorldStage(title: "Дахи", startHeight: 3_500),
                    WorldStage(title: "Над містом", startHeight: 6_000)]
        case .olympus:
            return [WorldStage(title: "Земля", startHeight: 0),
                    WorldStage(title: "Хмари", startHeight: 1_500),
                    WorldStage(title: "Олімп", startHeight: 3_500),
                    WorldStage(title: "Космос", startHeight: 6_500)]
        case .classic:
            return [WorldStage(title: "Зошит", startHeight: 0)]
        }
    }

    /// Етап для висоти (останній, початок якого вже пройдено).
    func stage(atHeight height: Double) -> WorldStage {
        stages.last { height >= $0.startHeight } ?? stages[0]
    }
}

/// Етап світу під час підйому.
struct WorldStage: Equatable {
    let title: String
    let startHeight: Double
}

/// Вигляд персонажа.
enum PlayerSkin: String, CaseIterable, Identifiable, Codable {
    case shades      // сонцезахисні окуляри
    case diver       // маска для пірнання
    case detective   // капелюх детектива
    case laurel      // лавровий вінок
    case doodle      // простий «намальований» персонаж

    var id: Self { self }

    var title: String {
        switch self {
        case .shades: return "Чілл"
        case .diver: return "Дайвер"
        case .detective: return "Детектив"
        case .laurel: return "Герой"
        case .doodle: return "Дудл"
        }
    }
}

/// Слід, який персонаж лишає за собою.
enum TrailStyle: String, CaseIterable, Identifiable, Codable {
    case none
    case neon
    case sparkles
    case bubbles
    case stars

    var id: Self { self }

    var title: String {
        switch self {
        case .none: return "Без сліду"
        case .neon: return "Неон"
        case .sparkles: return "Іскри"
        case .bubbles: return "Бульбашки"
        case .stars: return "Зірки"
        }
    }

    var emoji: String {
        switch self {
        case .none: return "🚫"
        case .neon: return "〰️"
        case .sparkles: return "✨"
        case .bubbles: return "🫧"
        case .stars: return "⭐️"
        }
    }
}
