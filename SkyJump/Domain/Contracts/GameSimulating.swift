import Foundation

/// Запуск ігрової симуляції на заданому рівні.
protocol GameSimulating {
    func simulate(playerName: String, level: [Platform], duration: Double) -> GameReport
}

/// Результат симуляції: журнал подій і підсумок.
struct GameReport {
    let log: [String]
    let summary: GameSummary
}

/// Дані підсумку без форматування — текст для екрана формує Presentation.
struct GameSummary {
    let playerName: String
    let isAlive: Bool
    let score: Int
    let jumpsCount: Int
    let brokenPlatformsCount: Int
    let highestPlatformY: Double?
    let platformsLeft: [PlatformType: Int]
}
