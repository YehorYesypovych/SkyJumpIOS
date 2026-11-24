import Foundation
import Observation

/// ViewModel екрана гри: запускає симуляцію рівня за пресетом,
/// записує результат у бібліотеку (рекорд рівня) і в загальне сховище рекорду.
@Observable
final class GameViewModel {
    private(set) var logLines: [String] = []
    private(set) var summaryText: String?
    private(set) var score = 0
    private(set) var isNewRecord = false
    private(set) var hasResult = false
    private(set) var isLogExpanded = false

    @ObservationIgnored let levelID: LevelPreset.ID
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private let simulator: any GameSimulating
    @ObservationIgnored private let scoreStore: any ScoreStoring
    @ObservationIgnored private weak var navigator: AppNavigating?
    @ObservationIgnored private let formatter: GameSummaryFormatter
    @ObservationIgnored private let playerName: String
    @ObservationIgnored private let duration: Double

    init(levelID: LevelPreset.ID,
         library: LevelLibrary,
         simulator: any GameSimulating,
         scoreStore: any ScoreStoring,
         navigator: AppNavigating,
         formatter: GameSummaryFormatter = GameSummaryFormatter(),
         playerName: String = "Doodler",
         duration: Double = 8) {
        self.levelID = levelID
        self.library = library
        self.simulator = simulator
        self.scoreStore = scoreStore
        self.navigator = navigator
        self.formatter = formatter
        self.playerName = playerName
        self.duration = duration
    }

    /// Актуальний рівень з бібліотеки; nil, якщо його видалили.
    var level: LevelPreset? { library.level(id: levelID) }

    var title: String { level?.name ?? "Гра" }

    /// Запускає гру на рівні. Рекорд рівня оновлюється в бібліотеці,
    /// тому екрани деталей і списку після повернення показують нові дані.
    func start() {
        guard let level else { return }
        let report = simulator.simulate(playerName: playerName,
                                        level: PresetLevelProvider(preset: level).makeLevel(),
                                        duration: duration)
        logLines = report.log
        summaryText = formatter.format(report.summary)
        score = report.summary.score
        isNewRecord = library.recordResult(levelID: levelID, score: score)
        scoreStore.submit(score: score)
        hasResult = true
    }

    func toggleLog() {
        isLogExpanded.toggle()
    }

    // MARK: - Навігація

    func backToLevel() {
        navigator?.pop()
    }

    func backToList() {
        navigator?.popToRoot()
    }
}
