import Foundation

/// Composition root: єдине місце, де обираються конкретні реалізації сервісів.
/// Решта коду отримує їх через init і знає лише протоколи.
struct AppDependencies {
    let levelProvider: any LevelProviding
    let simulator: any GameSimulating
    let scoreStore: any ScoreStoring

    /// Залежності для реального запуску застосунку.
    static func live() -> AppDependencies {
        AppDependencies(levelProvider: DemoLevelProvider(),
                        simulator: GameSimulationService(),
                        scoreStore: InMemoryScoreStore())
    }

    func makeDemoViewModel() -> DemoViewModel {
        DemoViewModel(levelProvider: levelProvider,
                      simulator: simulator,
                      scoreStore: scoreStore)
    }
}
