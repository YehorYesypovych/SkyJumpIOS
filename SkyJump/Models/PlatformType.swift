import Foundation

/// Тип платформи визначає, що відбувається, коли гравець на неї приземляється.
enum PlatformType: String, CaseIterable {
    case normal
    case moving
    case breakable
    case spring

    /// Швидкість стрибка з цієї платформи.
    /// Optional: у ламкої платформи стрибка немає — вона ламається (nil).
    var jumpVelocity: Double? {
        switch self {
        case .normal, .moving:
            return GameConfig.jumpVelocity
        case .spring:
            return GameConfig.jumpVelocity * GameConfig.springMultiplier
        case .breakable:
            return nil
        }
    }

    var title: String {
        switch self {
        case .normal: return "звичайна"
        case .moving: return "рухома"
        case .breakable: return "ламка"
        case .spring: return "з пружиною"
        }
    }
}
