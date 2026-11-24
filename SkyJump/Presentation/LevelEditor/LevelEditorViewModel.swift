import Foundation
import Observation

/// ViewModel модального редактора рівня (створення і редагування).
///
/// Редактор працює з чернеткою `draft` — копією рівня (struct, семантика значення).
/// Поки користувач не натиснув «Зберегти», зміни не потрапляють у `LevelLibrary`,
/// тому «Скасувати» нічого не потрібно відкочувати.
@Observable
final class LevelEditorViewModel {
    @ObservationIgnored let mode: LevelEditorMode
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private weak var navigator: AppNavigating?
    /// Стан рівня на момент відкриття редактора — з ним порівнюється чернетка.
    @ObservationIgnored private let original: LevelPreset

    /// Чернетка, яку редагує форма.
    var draft: LevelPreset

    init(mode: LevelEditorMode, library: LevelLibrary, navigator: AppNavigating) {
        self.mode = mode
        self.library = library
        self.navigator = navigator

        let initial: LevelPreset
        switch mode {
        case .create:
            initial = LevelPreset.makeNew()
        case .edit(let id):
            initial = library.level(id: id) ?? LevelPreset.makeNew()
        }
        self.original = initial
        self.draft = initial
    }

    var title: String {
        switch mode {
        case .create: return "Новий рівень"
        case .edit: return "Редагування"
        }
    }

    /// Назва без пробілів на початку й у кінці — саме її буде збережено.
    private var trimmedName: String {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Що не так із чернеткою; `nil`, якщо її можна зберегти.
    var validationMessage: String? {
        if trimmedName.isEmpty {
            return "Введіть назву рівня"
        }
        if trimmedName.count > LevelPreset.maxNameLength {
            return "Назва задовга: максимум \(LevelPreset.maxNameLength) символів"
        }
        if !LevelPreset.platformCountRange.contains(draft.platformCount) {
            let range = LevelPreset.platformCountRange
            return "Кількість платформ має бути від \(range.lowerBound) до \(range.upperBound)"
        }
        return nil
    }

    var canSave: Bool {
        validationMessage == nil
    }

    /// Чи є незбережені зміни (тоді модальне вікно не закривається свайпом).
    var hasChanges: Bool {
        draft != original
    }

    func regenerateSeed() {
        var newSeed = UInt64.random(in: 1...999_999)
        while newSeed == draft.seed {
            newSeed = UInt64.random(in: 1...999_999)
        }
        draft.seed = newSeed
    }

    func save() {
        guard canSave else { return }
        var level = draft
        level.name = trimmedName

        switch mode {
        case .create:
            library.add(level)
        case .edit:
            library.update(level)
        }
        navigator?.dismissSheet()
    }

    func cancel() {
        navigator?.dismissSheet()
    }
}
