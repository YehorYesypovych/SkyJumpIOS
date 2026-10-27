import Foundation

/// Сервіс симуляції: створює сесію, проганяє її і повертає результат.
struct GameSimulationService: GameSimulating {
    func simulate(playerName: String, level: [Platform], duration: Double) -> GameReport {
        let recorder = EventLogRecorder()
        let session = GameSession(playerName: playerName, platforms: level, observers: [recorder])
        session.run(duration: duration)
        return GameReport(log: recorder.lines, summary: session.makeSummary())
    }
}
