import Foundation
import Observation

/// ViewModel списку рівнів: віддає View дані з бібліотеки і передає дії користувача роутеру.
@Observable
final class LevelListViewModel {
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored private weak var navigator: AppNavigating?

    init(library: LevelLibrary, navigator: AppNavigating) {
        self.library = library
        self.navigator = navigator
    }

    /// Читається з бібліотеки щоразу, тому після створення чи редагування список оновлюється сам.
    var levels: [LevelPreset] { library.levels }

    var isEmpty: Bool { levels.isEmpty }

    func subtitle(for level: LevelPreset) -> String {
        "\(level.difficulty.title) · платформ: \(level.platformCount)"
    }

    func recordText(for level: LevelPreset) -> String {
        level.bestScore > 0
            ? "Рекорд: \(level.bestScore) · ігор: \(level.playsCount)"
            : "Ще не грали"
    }

    // MARK: - Дії користувача

    func open(_ id: LevelPreset.ID) {
        navigator?.showLevel(id)
    }

    func create() {
        navigator?.presentCreateLevel()
    }

    func openDemo() {
        navigator?.showDemo()
    }

    func openRadio() {
        navigator?.showRadio()
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { levels[$0].id }
        ids.forEach { library.delete(id: $0) }
    }
}
