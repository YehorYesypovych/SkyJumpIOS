import Foundation

/// Складність рівня: визначає допустимі типи платформ і відстань між ними.
enum LevelDifficulty: String, CaseIterable, Identifiable, Hashable {
    case easy
    case normal
    case hard

    var id: Self { self }

    var title: String {
        switch self {
        case .easy: return "Легкий"
        case .normal: return "Звичайний"
        case .hard: return "Складний"
        }
    }

    /// Які типи платформ можуть з'являтися на рівні.
    var allowedTypes: [PlatformType] {
        switch self {
        case .easy: return [.normal, .spring]
        case .normal: return PlatformType.allCases
        case .hard: return [.normal, .moving, .breakable]
        }
    }

    /// Відстань між платформами по вертикалі.
    var verticalStep: Double {
        switch self {
        case .easy: return 100
        case .normal: return 110
        case .hard: return 130
        }
    }
}

/// Пресет рівня з бібліотеки «Мої рівні». За пресетом рівень генерується однаково щоразу.
struct LevelPreset: Identifiable, Hashable {
    let id: UUID
    var name: String
    var platformCount: Int
    var difficulty: LevelDifficulty
    var seed: UInt64                // однаковий seed — однаковий рівень
    var bestScore: Int = 0          // 0 — ще не грали
    var playsCount: Int = 0

    static let platformCountRange = 5...50
    static let maxNameLength = 30

    /// Чернетка нового рівня для редактора.
    static func makeNew() -> LevelPreset {
        LevelPreset(id: UUID(),
                    name: "",
                    platformCount: 15,
                    difficulty: .normal,
                    seed: UInt64.random(in: 1...999_999))
    }

    /// Демо-дані бібліотеки на цьому етапі.
    static let samples: [LevelPreset] = [
        LevelPreset(id: UUID(), name: "Розминка", platformCount: 10, difficulty: .easy, seed: 1),
        LevelPreset(id: UUID(), name: "Класика", platformCount: 20, difficulty: .normal, seed: 42),
        LevelPreset(id: UUID(), name: "Хардкор", platformCount: 30, difficulty: .hard, seed: 7)
    ]
}
