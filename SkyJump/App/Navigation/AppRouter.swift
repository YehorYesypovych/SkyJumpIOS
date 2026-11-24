import Foundation
import Observation

/// Router: зберігає стан навігації (стек екранів і модальне вікно)
/// і змінює його за запитами ViewModel через `AppNavigating`.
/// Тримає лише значення маршрутів, а не екрани чи ViewModel.
@Observable
final class AppRouter: AppNavigating {
    var path: [Route] = []
    var sheet: Sheet?

    func showLevel(_ id: LevelPreset.ID) {
        path.append(.levelDetail(id))
    }

    func startGame(_ id: LevelPreset.ID) {
        path.append(.play(id))
    }

    func simulateLevel(_ id: LevelPreset.ID) {
        path.append(.game(id))
    }

    func showDemo() {
        path.append(.demo)
    }

    func showRadio() {
        path.append(.radio)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func presentCreateLevel() {
        sheet = .createLevel
    }

    func presentEditLevel(_ id: LevelPreset.ID) {
        sheet = .editLevel(id)
    }

    func dismissSheet() {
        sheet = nil
    }
}
