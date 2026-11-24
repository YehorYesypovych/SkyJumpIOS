import Foundation
import Observation

/// Єдине джерело правди для рівнів. Екрани отримують рівень за id і читають його звідси,
/// тому після створення чи редагування всі екрани бачать актуальні дані.
/// На цьому етапі рівні зберігаються в пам'яті, стартовий набір — демо-дані.
@Observable
final class LevelLibrary {
    private(set) var levels: [LevelPreset]

    init(levels: [LevelPreset] = LevelPreset.samples) {
        self.levels = levels
    }

    func level(id: LevelPreset.ID) -> LevelPreset? {
        levels.first { $0.id == id }
    }

    func add(_ level: LevelPreset) {
        levels.append(level)
    }

    func update(_ level: LevelPreset) {
        guard let index = levels.firstIndex(where: { $0.id == level.id }) else { return }
        levels[index] = level
    }

    func delete(id: LevelPreset.ID) {
        levels.removeAll { $0.id == id }
    }

    /// Записує результат гри. Повертає true, якщо це новий рекорд рівня.
    @discardableResult
    func recordResult(levelID: LevelPreset.ID, score: Int) -> Bool {
        guard let index = levels.firstIndex(where: { $0.id == levelID }) else { return false }
        levels[index].playsCount += 1
        guard score > levels[index].bestScore else { return false }
        levels[index].bestScore = score
        return true
    }
}
