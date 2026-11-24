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
    /// Генерація рівня запам'ятовується: поки параметри генерації не змінились, рівень не будується вдруге.
    var platformStats: [(PlatformType, Int)] {
        guard let level else { return [] }
        let key = StatsKey(level: level)
        if let cached = statsCache, cached.key == key {
            return cached.stats
        }
        let platforms = PresetLevelProvider(preset: level).makeLevel()
        let counts = Dictionary(grouping: platforms, by: \.type).mapValues(\.count)
        let stats = PlatformType.allCases.compactMap { type in
            counts[type].map { (type, $0) }
        }
        statsCache = (key, stats)
        return stats
    }

    /// Від чого залежить згенерований рівень (назва чи рекорд на нього не впливають).
    private struct StatsKey: Equatable {
        let seed: UInt64
        let platformCount: Int
        let difficulty: LevelDifficulty

        init(level: LevelPreset) {
            seed = level.seed
            platformCount = level.platformCount
            difficulty = level.difficulty
        }
    }

    @ObservationIgnored private var statsCache: (key: StatsKey, stats: [(PlatformType, Int)])?

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

    /// Швидка симуляція рівня без керування (8 с), як у демо-сценарії.
    func simulate() {
        navigator?.simulateLevel(levelID)
    }

    func backToList() {
        navigator?.popToRoot()
    }
}
