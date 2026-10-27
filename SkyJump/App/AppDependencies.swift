import Foundation

/// Composition root: єдине місце, де обираються конкретні реалізації сервісів.
/// Решта коду отримує їх через init і знає лише протоколи.
struct AppDependencies {
    let levelProvider: any LevelProviding
    let simulator: any GameSimulating
    let scoreStore: any ScoreStoring

    /// Залежності для реального запуску застосунку.
    /// Аргумент запуску `-randomLevel` (Edit Scheme → Run → Arguments) вмикає випадковий рівень.
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        let levelProvider: any LevelProviding = arguments.contains("-randomLevel")
            ? RandomLevelProvider()
            : DemoLevelProvider()

        // Журнал подій додатково дублюється в консоль Xcode
        return AppDependencies(levelProvider: levelProvider,
                               simulator: GameSimulationService(observers: [ConsoleEventLogger()]),
                               scoreStore: UserDefaultsScoreStore(defaults: .standard))
    }

    func makeDemoViewModel() -> DemoViewModel {
        DemoViewModel(levelProvider: levelProvider,
                      simulator: simulator,
                      scoreStore: scoreStore)
    }
}
