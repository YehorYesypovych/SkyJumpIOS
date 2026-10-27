import Foundation

/// Тип платформи. Що відбувається при приземленні, визначає LandingStrategy
/// для цього типу (див. LandingStrategies).
enum PlatformType: String, CaseIterable {
    case normal
    case moving
    case breakable
    case spring

    var title: String {
        switch self {
        case .normal: return "звичайна"
        case .moving: return "рухома"
        case .breakable: return "ламка"
        case .spring: return "з пружиною"
        }
    }
}
