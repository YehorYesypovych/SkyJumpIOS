import Foundation
import Observation

/// ViewModel деталей рівня. Каркас: лише залежності; логіка — частина B.
@Observable
final class LevelDetailViewModel {
    @ObservationIgnored let levelID: LevelPreset.ID
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private weak var navigator: AppNavigating?

    init(levelID: LevelPreset.ID, library: LevelLibrary, navigator: AppNavigating) {
        self.levelID = levelID
        self.library = library
        self.navigator = navigator
    }
}
