import Foundation
import Observation

/// ViewModel справжньої гри: щокадру робить крок сесії з керуванням гравця,
/// стежить за паузою і кінцем гри та готує `GameFrame` для малювання.
@Observable
final class GameplayViewModel {
    private(set) var frame = GameFrame()
    private(set) var outcome: GameOutcome = .playing
    private(set) var isPaused = false
    private(set) var isNewRecord = false
    private(set) var hasStarted = false

    /// Найбільший крок фізики за кадр: після паузи чи підвисання гра не «перестрибує» платформи.
    static let maxDeltaTime = 1.0 / 30.0
    /// На якій висоті над нижнім краєм екрана тримається найвища точка гравця.
    static let cameraOffset = 320.0
    /// Наскільки нижче краю екрана має опуститися гравець, щоб гра закінчилась (≈ зріст персонажа).
    static let fallMargin = 60.0

    /// Правила для справжньої гри: межа падіння збігається з нижнім краєм екрана.
    /// Інакше гравець падав за екран, приземлявся на невидиму платформу і повертався.
    static func gameplayRules(from rules: GameRules) -> GameRules {
        var gameplay = rules
        gameplay.screenHeight = cameraOffset + fallMargin
        return gameplay
    }

    @ObservationIgnored private let round: GameRound
    @ObservationIgnored private let library: LevelLibrary
    @ObservationIgnored let levelID: LevelPreset.ID
    @ObservationIgnored private weak var navigator: AppNavigating?
    @ObservationIgnored private var input: Double = 0

    init(levelID: LevelPreset.ID,
         library: LevelLibrary,
         scoreStore: any ScoreStoring,
         navigator: AppNavigating,
         rules: GameRules = .standard,
         makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() }) {
        self.levelID = levelID
        self.library = library
        self.navigator = navigator
        self.round = GameRound(levelID: levelID,
                               library: library,
                               scoreStore: scoreStore,
                               rules: Self.gameplayRules(from: rules),
                               makeLevel: makeLevel)
    }

    /// Актуальний рівень з бібліотеки; nil, якщо його видалили.
    var level: LevelPreset? { library.level(id: levelID) }

    var title: String { level?.name ?? "Гра" }

    /// Рекорд рівня — оновлюється в бібліотеці одразу після кінця гри.
    var bestScore: Int { level?.bestScore ?? 0 }

    var isPlaying: Bool { hasStarted && !isPaused && outcome == .playing }

    // MARK: - Ігровий цикл

    func start() {
        round.start()
        input = 0
        isPaused = false
        isNewRecord = false
        outcome = .playing
        hasStarted = round.session != nil
        frame = makeFrame()
    }

    /// Один кадр гри. deltaTime — секунди від попереднього кадру.
    func tick(deltaTime: Double) {
        guard isPlaying, let session = round.session else { return }

        session.step(deltaTime: min(max(deltaTime, 0), Self.maxDeltaTime), input: input)

        if round.finishIfNeeded() {
            isNewRecord = round.isNewRecord
            outcome = session.outcome
            input = 0
        }
        frame = makeFrame()
    }

    /// Напрям керування: -1 — вліво, 0 — без руху, 1 — вправо.
    func setInput(_ direction: Double) {
        input = min(max(direction, -1), 1)
    }

    func pause() {
        guard hasStarted, outcome == .playing else { return }
        isPaused = true
        input = 0
    }

    func resume() {
        isPaused = false
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    func restart() {
        start()
    }

    // MARK: - Навігація

    func backToLevel() {
        navigator?.pop()
    }

    func backToList() {
        navigator?.popToRoot()
    }

    // MARK: - Кадр

    private func makeFrame() -> GameFrame {
        guard let session = round.session else { return GameFrame() }
        let player = session.player

        return GameFrame(
            platforms: session.platforms.map { platform in
                GameFrame.PlatformSprite(id: platform.id,
                                         x: platform.position.x,
                                         y: platform.position.y,
                                         width: platform.width,
                                         type: platform.type,
                                         isBroken: platform.isBroken)
            },
            playerX: player.position.x,
            playerY: player.position.y,
            playerWidth: player.width,
            isFalling: player.isFalling,
            // камера не опускається: тримається за найвищою точкою гравця
            cameraBottom: session.maxHeight - Self.cameraOffset,
            score: session.score,
            progress: session.progress
        )
    }
}
