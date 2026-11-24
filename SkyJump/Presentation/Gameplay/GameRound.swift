import Foundation

/// Один раунд справжньої гри на рівні: старт, фіксація кінця гри, запис рекорду, перезапуск.
/// Рекорд рівня пишеться в `LevelLibrary`, загальний — у `ScoreStoring`, рівно один раз за раунд.
final class GameRound {
    private(set) var session: GameSession?     // nil — рівень не знайдено
    private(set) var isNewRecord = false
    private(set) var isFinished = false        // результат уже записано

    private let levelID: LevelPreset.ID
    private let library: LevelLibrary
    private let scoreStore: any ScoreStoring
    private let rules: GameRules
    private let playerName: String
    private let makeLevel: (LevelPreset) -> [Platform]
    private let makePickups: ([Platform], LevelPreset) -> [Pickup]

    /// makeLevel — як отримати платформи з пресета; у тестах підставляється готовий рівень.
    init(levelID: LevelPreset.ID,
         library: LevelLibrary,
         scoreStore: any ScoreStoring,
         rules: GameRules = .standard,
         playerName: String = "Doodler",
         makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() },
         makePickups: @escaping ([Platform], LevelPreset) -> [Pickup] = { GameRound.makeJetpacks(on: $0, seed: $1.seed) }) {
        self.levelID = levelID
        self.library = library
        self.scoreStore = scoreStore
        self.rules = rules
        self.playerName = playerName
        self.makeLevel = makeLevel
        self.makePickups = makePickups
    }

    /// Ширина «ніг» персонажа в грі: приземлення там, де персонаж візуально стоїть на платформі.
    static let footWidth = GameConfig.playerWidth * 0.6

    var level: LevelPreset? { library.level(id: levelID) }

    var outcome: GameOutcome { session?.outcome ?? .lost }

    /// Нова сесія з пресета в режимі гри до верхньої платформи.
    func start() {
        isNewRecord = false
        isFinished = false
        guard let level else {
            session = nil
            return
        }
        let platforms = makeLevel(level)
        session = GameSession(playerName: playerName,
                              platforms: platforms,
                              rules: rules,
                              completesAtTop: true,
                              footWidth: Self.footWidth,
                              pickups: makePickups(platforms, level))
    }

    /// Джетпаки на рівні: один приблизно на 15 платформ, лише на звичайних платформах
    /// не біля старту й не біля верху. Розташування залежить від seed, тож рівень повторюється.
    static func makeJetpacks(on platforms: [Platform], seed: UInt64) -> [Pickup] {
        let count = platforms.count / 15
        guard count > 0 else { return [] }

        var generator = SeededRandomGenerator(seed: seed &+ 0x5EED)
        let candidates = platforms.filter { platform in
            platform.type == .normal && platform.id >= 3 && platform.id < platforms.count - 3
        }
        return candidates
            .shuffled(using: &generator)
            .prefix(count)
            .sorted { $0.position.y < $1.position.y }
            .enumerated()
            .map { index, platform in
                Pickup(id: index, kind: .jetpack,
                       x: platform.position.x + platform.width / 2,
                       y: platform.position.y)
            }
    }

    /// Якщо гра щойно закінчилась — записує результат. Повертає true лише в момент завершення.
    @discardableResult
    func finishIfNeeded() -> Bool {
        guard let session, session.outcome != .playing, !isFinished else { return false }
        isFinished = true
        isNewRecord = library.recordResult(levelID: levelID, score: session.score)
        scoreStore.submit(score: session.score)
        return true
    }
}
