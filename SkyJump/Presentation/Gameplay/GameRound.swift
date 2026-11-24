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

    /// makeLevel — як отримати платформи з пресета; у тестах підставляється готовий рівень.
    init(levelID: LevelPreset.ID,
         library: LevelLibrary,
         scoreStore: any ScoreStoring,
         rules: GameRules = .standard,
         playerName: String = "Doodler",
         makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() }) {
        self.levelID = levelID
        self.library = library
        self.scoreStore = scoreStore
        self.rules = rules
        self.playerName = playerName
        self.makeLevel = makeLevel
    }

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
        session = GameSession(playerName: playerName,
                              platforms: makeLevel(level),
                              rules: rules,
                              completesAtTop: true)
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
