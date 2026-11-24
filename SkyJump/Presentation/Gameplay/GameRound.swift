import Foundation

/// Режим гри: рівень з бібліотеки або нескінченний підйом.
enum GameMode: Hashable {
    case level(LevelPreset.ID)
    case endless
}

/// Один раунд справжньої гри: старт, фіксація кінця гри, запис рекорду, перезапуск.
/// Рекорд рівня пишеться в `LevelLibrary`, рекорд нескінченного режиму — в окреме сховище,
/// загальний — у `ScoreStoring`; рівно один раз за раунд.
final class GameRound {
    private(set) var session: GameSession?     // nil — рівень не знайдено
    private(set) var isNewRecord = false
    private(set) var isFinished = false        // результат уже записано

    let mode: GameMode
    private let library: LevelLibrary
    private let endlessScores: any ScoreStoring
    private var endlessGenerator: EndlessLevelGenerator?
    private let scoreStore: any ScoreStoring
    private let rules: GameRules
    private let playerName: String
    private let makeLevel: (LevelPreset) -> [Platform]
    private let makePickups: ([Platform], LevelPreset) -> [Pickup]

    convenience init(levelID: LevelPreset.ID,
         library: LevelLibrary,
         scoreStore: any ScoreStoring,
         endlessScores: any ScoreStoring = InMemoryScoreStore(),
         rules: GameRules = .standard,
         playerName: String = "Doodler",
         makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() },
         makePickups: @escaping ([Platform], LevelPreset) -> [Pickup] = { GameRound.makeJetpacks(on: $0, seed: $1.seed) }) {
        self.init(mode: .level(levelID), library: library, scoreStore: scoreStore, endlessScores: endlessScores,
                  rules: rules, playerName: playerName, makeLevel: makeLevel, makePickups: makePickups)
    }

    /// makeLevel — як отримати платформи з пресета; у тестах підставляється готовий рівень.
    init(mode: GameMode,
         library: LevelLibrary,
         scoreStore: any ScoreStoring,
         endlessScores: any ScoreStoring,
         rules: GameRules = .standard,
         playerName: String = "Doodler",
         makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() },
         makePickups: @escaping ([Platform], LevelPreset) -> [Pickup] = { GameRound.makeJetpacks(on: $0, seed: $1.seed) }) {
        self.mode = mode
        self.library = library
        self.endlessScores = endlessScores
        self.scoreStore = scoreStore
        self.rules = rules
        self.playerName = playerName
        self.makeLevel = makeLevel
        self.makePickups = makePickups
    }

    /// Ширина «ніг» персонажа в грі: приземлення там, де персонаж візуально стоїть на платформі.
    static let footWidth = GameConfig.playerWidth * 0.6

    var level: LevelPreset? {
        guard case .level(let id) = mode else { return nil }
        return library.level(id: id)
    }

    /// Рекорд поточного режиму: рівня або нескінченного підйому.
    var bestScore: Int {
        switch mode {
        case .level: return level?.bestScore ?? 0
        case .endless: return endlessScores.bestScore
        }
    }

    var outcome: GameOutcome { session?.outcome ?? .lost }

    /// Нова сесія: з пресета до верхньої платформи або нескінченна.
    func start() {
        isNewRecord = false
        isFinished = false
        if case .endless = mode {
            startEndless()
            return
        }
        guard let level else {
            session = nil
            return
        }
        let platforms = makeLevel(level)
        session = GameSession(playerName: playerName,
                              platforms: platforms,
                              rules: rules,
                              landingStrategies: LandingStrategies.gameplay(rules: rules),
                              completesAtTop: true,
                              footWidth: Self.footWidth,
                              pickups: makePickups(platforms, level))
    }

    private func startEndless() {
        let generator = EndlessLevelGenerator(seed: UInt64.random(in: 1...UInt64.max))
        let start = generator.start()
        endlessGenerator = generator
        session = GameSession(playerName: playerName,
                              platforms: start.platforms,
                              rules: rules,
                              landingStrategies: LandingStrategies.gameplay(rules: rules),
                              completesAtTop: false,
                              footWidth: Self.footWidth,
                              pickups: start.pickups)
    }

    /// Нескінченний режим: добудовує рівень над гравцем. Викликається після кожного кроку гри.
    func extendIfNeeded() {
        guard let session, let endlessGenerator else { return }
        let target = session.maxHeight + EndlessLevelGenerator.lookahead
        guard endlessGenerator.topHeight < target else { return }
        let added = endlessGenerator.extend(upTo: target)
        session.extendLevel(platforms: added.platforms, pickups: added.pickups)
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
        switch mode {
        case .level(let id):
            isNewRecord = library.recordResult(levelID: id, score: session.score)
        case .endless:
            isNewRecord = endlessScores.submit(score: session.score)
        }
        scoreStore.submit(score: session.score)
        return true
    }
}
