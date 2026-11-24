import Foundation
import Observation

/// ViewModel списку рівнів. Каркас: показ рівнів і переходи; повна логіка — частина A.
@Observable
final class LevelListViewModel {
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private weak var navigator: AppNavigating?

    init(library: LevelLibrary, navigator: AppNavigating) {
        self.library = library
        self.navigator = navigator
    }

    var levels: [LevelPreset] { library.levels }

    func open(_ id: LevelPreset.ID) {
        navigator?.showLevel(id)
    }

    func create() {
        navigator?.presentCreateLevel()
    }
}
