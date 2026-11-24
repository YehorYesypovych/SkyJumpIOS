import Foundation
import Observation

/// ViewModel екрана гри. Каркас: лише залежності; логіка — частина A.
@Observable
final class GameViewModel {
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
}
