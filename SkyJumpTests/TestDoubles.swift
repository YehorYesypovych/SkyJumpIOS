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

/// Запам'ятовує, які переходи просила ViewModel.
/// ViewModel тримає навігатор слабким посиланням, тому в тесті його треба зберегти в локальній змінній.
@MainActor
final class SpyNavigator: AppNavigating {
    private(set) var calls: [String] = []

    func showLevel(_ id: LevelPreset.ID) { calls.append("showLevel") }
    func startGame(_ id: LevelPreset.ID) { calls.append("startGame") }
    func simulateLevel(_ id: LevelPreset.ID) { calls.append("simulateLevel") }
    func showDemo() { calls.append("showDemo") }
    func showRadio() { calls.append("showRadio") }
    func pop() { calls.append("pop") }
    func popToRoot() { calls.append("popToRoot") }
    func presentCreateLevel() { calls.append("presentCreateLevel") }
    func presentEditLevel(_ id: LevelPreset.ID) { calls.append("presentEditLevel") }
    func dismissSheet() { calls.append("dismissSheet") }
}

/// Запам'ятовує, що просили програти; стан повідомляє одразу.
@MainActor
final class SpyStreamer: AudioStreaming {
    var onStateChange: ((StreamState) -> Void)?
    var volume: Float = 1
    private(set) var playedURLs: [URL] = []
    private(set) var stopCount = 0

    func play(url: URL) {
        playedURLs.append(url)
        onStateChange?(.playing)
    }

    func stop() {
        stopCount += 1
        onStateChange?(.idle)
    }
}

/// Каталог радіо з наперед заданою відповіддю або помилкою.
struct StubStationsProvider: RadioStationProviding {
    var result: Result<[RadioStation], Error>

    func stations(for genres: [RadioGenre]) async throws -> [RadioStation] {
        try result.get()
    }
}
