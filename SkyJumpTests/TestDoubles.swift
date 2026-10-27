@testable import SkyJump

/// Spy-спостерігач: запам'ятовує всі події, які надіслала сесія.
final class SpyObserver: GameEventObserver {
    private(set) var events: [GameEvent] = []

    func gameSession(didEmit event: GameEvent, at time: Double) {
        events.append(event)
    }
}

/// Фіксований маленький рівень для тестів.
struct TestLevelProvider: LevelProviding {
    func makeLevel() -> [Platform] {
        [
            Platform(id: 0, x: 160, y: 0),
            Platform(id: 1, x: 160, y: 120),
            Platform(id: 2, x: 160, y: 240)
        ]
    }
}

/// Стратегія-шпигун: рахує приземлення і завжди ламає платформу.
final class CountingBreakLanding: LandingStrategy {
    private(set) var landingsCount = 0

    func land(player: Player, on platform: inout Platform) -> LandingOutcome {
        landingsCount += 1
        platform.breakPlatform()
        return .broke
    }
}
