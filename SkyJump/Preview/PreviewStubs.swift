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
                        scoreStore: InMemoryScoreStore(bestScore: 500),
                        endlessScores: InMemoryScoreStore(bestScore: 2_400),
                        library: LevelLibrary(),
                        radio: .preview(),
                        radioProvider: StubRadioProvider(),
                        cosmetics: CosmeticsSettings(defaults: UserDefaults(suiteName: "preview.cosmetics") ?? .standard))
    }

    /// Справжня симуляція на тестовому рівні — замінено лише джерело рівня і сховище.
    static func previewWithRealSimulation() -> AppDependencies {
        AppDependencies(levelProvider: StubLevelProvider(),
                        simulator: GameSimulationService(),
                        scoreStore: InMemoryScoreStore(),
                        endlessScores: InMemoryScoreStore(),
                        library: LevelLibrary(),
                        radio: .preview(),
                        radioProvider: StubRadioProvider(),
                        cosmetics: CosmeticsSettings(defaults: UserDefaults(suiteName: "preview.cosmetics") ?? .standard))
    }
}

/// Програвач без звуку: одразу «грає», нічого не завантажуючи.
final class SilentStreamer: AudioStreaming {
    var onStateChange: ((StreamState) -> Void)?
    var volume: Float = 1

    func play(url: URL) {
        onStateChange?(.playing)
    }

    func stop() {
        onStateChange?(.idle)
    }
}

/// Заготовлені станції для Preview — без мережі.
struct StubRadioProvider: RadioStationProviding {
    static let stations: [RadioStation] = [
        RadioStation(id: "stub-1", name: "Neon Beach FM", streamURL: URL(string: "https://example.com/neon.mp3")!,
                     country: "United States", countryCode: "US", tags: ["synthwave", "80s"],
                     faviconURL: nil, bitrate: 128),
        RadioStation(id: "stub-2", name: "Palm Drive Radio", streamURL: URL(string: "https://example.com/palm.mp3")!,
                     country: "Germany", countryCode: "DE", tags: ["retrowave"],
                     faviconURL: nil, bitrate: 192),
        RadioStation(id: "stub-3", name: "Vapor Sunset", streamURL: URL(string: "https://example.com/vapor.aac")!,
                     country: "Ukraine", countryCode: "UA", tags: ["vaporwave", "chillwave"],
                     faviconURL: nil, bitrate: 96)
    ]

    func stations(for genres: [RadioGenre]) async throws -> [RadioStation] {
        Self.stations
    }
}

extension RadioPlayer {
    /// Радіо для Preview: без звуку, з окремим сховищем, щоб не чіпати справжні налаштування.
    static func preview() -> RadioPlayer {
        RadioPlayer(streamer: SilentStreamer(),
                    defaults: UserDefaults(suiteName: "preview.radio") ?? .standard)
    }
}

