import Foundation

/// Сервіс симуляції: створює сесію, проганяє її і повертає результат.
struct GameSimulationService: GameSimulating {
    func simulate(playerName: String, level: [Platform], duration: Double) -> GameReport {
        let session = GameSession(playerName: playerName, platforms: level)
        session.run(duration: duration)
        return GameReport(log: session.log, summary: session.makeSummary())
    }
}
