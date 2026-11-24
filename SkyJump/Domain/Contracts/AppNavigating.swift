import Foundation

/// Що ViewModel може попросити в навігації. ViewModel не знає, як саме влаштований стек екранів.
protocol AppNavigating: AnyObject {
    func showLevel(_ id: LevelPreset.ID)
    func startGame(_ id: LevelPreset.ID)
    func simulateLevel(_ id: LevelPreset.ID)
    func showDemo()
    func showRadio()
    func showCustomize()
    func pop()
    func popToRoot()
    func presentCreateLevel()
    func presentEditLevel(_ id: LevelPreset.ID)
    func dismissSheet()
}
