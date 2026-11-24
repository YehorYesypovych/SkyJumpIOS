import Foundation

/// Екрани стекової навігації (push).
enum Route: Hashable {
    case levelDetail(LevelPreset.ID)
    case game(LevelPreset.ID)
    case demo
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
