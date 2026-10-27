import Foundation
import Observation

/// ViewModel екрана демо-сценарію: тримає стан для View і викликає сервіси через протоколи.
@Observable
final class DemoViewModel {
    private(set) var logLines: [String] = []
    private(set) var summaryText: String?
    private(set) var bestScore: Int
    private(set) var isNewRecord = false

    @ObservationIgnored private let levelProvider: any LevelProviding
    @ObservationIgnored private let simulator: any GameSimulating
    @ObservationIgnored private let scoreStore: any ScoreStoring
    @ObservationIgnored private let formatter: GameSummaryFormatter
    @ObservationIgnored private let playerName: String
    @ObservationIgnored private let duration: Double

    init(levelProvider: any LevelProviding,
         simulator: any GameSimulating,
         scoreStore: any ScoreStoring,
         formatter: GameSummaryFormatter = GameSummaryFormatter(),
         playerName: String = "Doodler",
         duration: Double = 8) {
        self.levelProvider = levelProvider
        self.simulator = simulator
        self.scoreStore = scoreStore
        self.formatter = formatter
        self.playerName = playerName
        self.duration = duration
        self.bestScore = scoreStore.bestScore
    }

    func runDemo() {
        let report = simulator.simulate(playerName: playerName,
                                        level: levelProvider.makeLevel(),
                                        duration: duration)
        logLines = report.log
        summaryText = formatter.format(report.summary)
        isNewRecord = scoreStore.submit(score: report.summary.score)
        bestScore = scoreStore.bestScore
    }
}
