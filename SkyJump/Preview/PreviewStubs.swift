import Foundation

/// Тестові реалізації сервісів для Preview і перевірок.
/// Їх підставляють замість справжніх через AppDependencies — DemoViewModel і DemoView при цьому не змінюються.

/// Маленький рівень із трьох платформ.
struct StubLevelProvider: LevelProviding {
    func makeLevel() -> [Platform] {
        LevelBuilder()
            .platform(.normal, x: 160, y: 0)
            .platform(.spring, x: 150, y: 120)
            .platform(.normal, x: 140, y: 600)
            .build()
    }
}

/// Симулятор, який нічого не рахує і одразу повертає заготовлений результат.
struct StubGameSimulator: GameSimulating {
    func simulate(playerName: String, level: [Platform], duration: Double) -> GameReport {
        GameReport(
            log: [
                "[ 0.00 с] Старт: \(playerName), платформ на рівні: \(level.count)",
                "[ 0.02 с] Стрибок з платформи #0 (звичайна) на висоті 0",
                "[ 0.80 с] Стрибок з платформи #1 (з пружиною) на висоті 120",
                "[ 2.00 с] Симуляцію завершено"
            ],
            summary: GameSummary(playerName: playerName,
                                 isAlive: true,
                                 score: 600,
                                 jumpsCount: 2,
                                 brokenPlatformsCount: 0,
                                 highestPlatformY: 600,
                                 platformsLeft: [.normal: 2, .spring: 1])
        )
    }
}

extension AppDependencies {
    /// Повністю тестові залежності: заготовлений результат, рекорд лише в пам'яті.
    static func preview() -> AppDependencies {
        AppDependencies(levelProvider: StubLevelProvider(),
                        simulator: StubGameSimulator(),
                        scoreStore: InMemoryScoreStore(bestScore: 500))
    }

    /// Справжня симуляція на тестовому рівні — замінено лише джерело рівня і сховище.
    static func previewWithRealSimulation() -> AppDependencies {
        AppDependencies(levelProvider: StubLevelProvider(),
                        simulator: GameSimulationService(),
                        scoreStore: InMemoryScoreStore())
    }
}
