import Foundation

/// Екрани стекової навігації (push).
enum Route: Hashable {
    case levelDetail(LevelPreset.ID)
    case play(LevelPreset.ID)       // справжня гра з керуванням
    case endless                    // нескінченний режим
    case game(LevelPreset.ID)       // симуляція рівня (8 с без керування)
    case demo
    case radio
    case customize
    case leaderboard
}

/// Модальні екрани.
enum Sheet: Identifiable, Hashable {
    case createLevel
    case editLevel(LevelPreset.ID)

    var id: String {
        switch self {
        case .createLevel: return "create"
        case .editLevel(let id): return "edit-\(id)"
        }
    }
}

/// Режим редактора рівня.
enum LevelEditorMode: Hashable {
    case create
    case edit(LevelPreset.ID)
}
