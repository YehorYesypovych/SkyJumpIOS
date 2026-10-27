import Foundation

/// Сервіс симуляції: створює сесію, проганяє її і повертає результат.
/// Стратегії приземлення і додаткові спостерігачі передаються через init,
/// тому правила гри і куди йдуть події можна змінити, не чіпаючи сервіс і сесію.
struct GameSimulationService: GameSimulating {
    private let landingStrategies: [PlatformType: LandingStrategy]
    private let observers: [GameEventObserver]

    init(landingStrategies: [PlatformType: LandingStrategy] = LandingStrategies.standard,
         observers: [GameEventObserver] = []) {
        self.landingStrategies = landingStrategies
        self.observers = observers
    }

    func simulate(playerName: String, level: [Platform], duration: Double) -> GameReport {
        // Журнал для екрана збирається завжди, решта спостерігачів — додатково
        let recorder = EventLogRecorder()
        let session = GameSession(playerName: playerName,
                                  platforms: level,
                                  landingStrategies: landingStrategies,
                                  observers: [recorder] + observers)
        session.run(duration: duration)
        return GameReport(log: recorder.lines, summary: session.makeSummary())
    }
}
