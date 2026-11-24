import Foundation
import Observation

/// ViewModel редактора рівня. Каркас: лише залежності; логіка — частина B.
@Observable
final class LevelEditorViewModel {
    @ObservationIgnored let mode: LevelEditorMode
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private weak var navigator: AppNavigating?

    init(mode: LevelEditorMode, library: LevelLibrary, navigator: AppNavigating) {
        self.mode = mode
        self.library = library
        self.navigator = navigator
    }
}
