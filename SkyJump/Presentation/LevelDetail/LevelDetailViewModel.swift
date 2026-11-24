import Foundation
import Observation

/// ViewModel деталей рівня. Не зберігає копію рівня: щоразу читає його з `LevelLibrary`,
/// тому після редагування чи гри екран показує актуальні дані без додаткової синхронізації.
@Observable
final class LevelDetailViewModel {
    @ObservationIgnored let levelID: LevelPreset.ID
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private weak var navigator: AppNavigating?

    /// Чи розгорнута секція «Склад рівня».
    private(set) var isStatsExpanded = false

    init(levelID: LevelPreset.ID, library: LevelLibrary, navigator: AppNavigating) {
        self.levelID = levelID
        self.library = library
        self.navigator = navigator
    }

    /// Актуальний рівень з бібліотеки; `nil`, якщо рівень видалено.
    var level: LevelPreset? {
        library.level(id: levelID)
    }

    /// Скільки платформ кожного типу є на рівні (лише типи, що трапляються).
    /// Рахується з рівня, згенерованого за пресетом, тому збігається з тим, що буде в грі.
    var platformStats: [(PlatformType, Int)] {
        guard let level else { return [] }
        let platforms = PresetLevelProvider(preset: level).makeLevel()
        return PlatformType.allCases.compactMap { type in
            let count = platforms.filter { $0.type == type }.count
            return count > 0 ? (type, count) : nil
        }
    }

    /// Текст рекорду для показу: «ще не грали», поки рекорду немає.
    var bestScoreText: String {
        guard let level, level.bestScore > 0 else { return "ще не грали" }
        return "\(level.bestScore)"
    }

    func toggleStats() {
        isStatsExpanded.toggle()
    }

    func edit() {
        navigator?.presentEditLevel(levelID)
    }

    func play() {
        navigator?.startGame(levelID)
    }

    func backToList() {
        navigator?.popToRoot()
    }
}
