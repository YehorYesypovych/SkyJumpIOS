import Foundation
import Observation

/// ViewModel справжньої гри: щокадру робить крок сесії з керуванням гравця,
/// стежить за паузою і кінцем гри та готує `GameFrame` для малювання.
@Observable
final class GameplayViewModel {
    /// Числа для HUD. Окремо від кадру: кадр змінюється 60 разів на секунду і перемальовує лише Canvas,
    /// а HUD оновлюється тільки тоді, коли змінилося те, що на ньому видно.
    struct HUDState: Equatable {
        var score = 0
        var progress: Double = 0       // округлено до 1 %
        var jetpackLeft: Double = 0    // округлено до 2 %
    }

    private(set) var frame = GameFrame()
    private(set) var hud = HUDState()
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
    @ObservationIgnored let mode: GameMode
    @ObservationIgnored private weak var navigator: AppNavigating?
    @ObservationIgnored private var input: Double = 0
    @ObservationIgnored private var trail: [GameFrame.TrailPoint] = []

    /// Скільки точок сліду пам'ятати і як часто їх ставити (одиниці світу між точками).
    static let trailLength = 16
    static let trailSpacing = 7.0
    @ObservationIgnored private let jetpackDuration: Double
    /// Куди віддати рахунок нескінченного режиму (таблиця лідерів); nil — нікуди.
    @ObservationIgnored private let scoreReporter: (any ScoreReporting)?

    convenience init(levelID: LevelPreset.ID,
                     library: LevelLibrary,
                     scoreStore: any ScoreStoring,
                     navigator: AppNavigating,
                     rules: GameRules = .standard,
                     makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() }) {
        self.init(mode: .level(levelID), library: library, scoreStore: scoreStore,
                  endlessScores: InMemoryScoreStore(), navigator: navigator, rules: rules, makeLevel: makeLevel)
    }

    init(mode: GameMode,
         library: LevelLibrary,
         scoreStore: any ScoreStoring,
         endlessScores: any ScoreStoring,
         navigator: AppNavigating,
         scoreReporter: (any ScoreReporting)? = nil,
         rules: GameRules = .standard,
         makeLevel: @escaping (LevelPreset) -> [Platform] = { PresetLevelProvider(preset: $0).makeLevel() }) {
        self.mode = mode
        self.scoreReporter = scoreReporter
        self.jetpackDuration = max(rules.jetpackDuration, 0.01)
        self.library = library
        self.navigator = navigator
        self.round = GameRound(mode: mode,
                               library: library,
                               scoreStore: scoreStore,
                               endlessScores: endlessScores,
                               rules: Self.gameplayRules(from: rules),
                               makeLevel: makeLevel)
    }

    /// Актуальний рівень з бібліотеки; nil — рівень видалили або це нескінченний режим.
    var level: LevelPreset? { round.level }

    var isEndless: Bool { mode == .endless }

    /// Рівень видалили — грати нема в що.
    var isUnavailable: Bool { !isEndless && level == nil }

    var title: String { isEndless ? "Нескінченний режим" : (level?.name ?? "Гра") }

    /// Рекорд рівня або нескінченного режиму — оновлюється одразу після кінця гри.
    var bestScore: Int { round.bestScore }

    var isPlaying: Bool { hasStarted && !isPaused && outcome == .playing }

    // MARK: - Ігровий цикл

    func start() {
        round.start()
        input = 0
        isPaused = false
        isNewRecord = false
        outcome = .playing
        trail = []
        hasStarted = round.session != nil
        updateFrame()
    }

    /// Один кадр гри. deltaTime — секунди від попереднього кадру.
    func tick(deltaTime: Double) {
        guard isPlaying, let session = round.session else { return }

        session.step(deltaTime: min(max(deltaTime, 0), Self.maxDeltaTime), input: input)
        round.extendIfNeeded()

        if round.finishIfNeeded() {
            isNewRecord = round.isNewRecord
            outcome = session.outcome
            input = 0
            if isEndless {
                scoreReporter?.report(score: session.score)
            }
        }
        updateFrame()
    }

    /// Напрям керування: -1 — вліво, 0 — без руху, 1 — вправо.
    func setInput(_ direction: Double) {
        input = min(max(direction, -1), 1)
    }

    /// Запас над і під екраном, у межах якого об'єкти ще потрапляють у кадр (одиниці світу).
    static let cullingMargin = 60.0
    /// Видима висота світу з запасом: на найвищих iPhone видно ~ 900 одиниць.
    static let visibleWorldHeight = 1000.0

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

    /// Оновлює кадр і, лише якщо щось змінилось на екрані, — HUD.
    private func updateFrame() {
        updateTrail()
        frame = makeFrame()
        let newHUD = HUDState(score: frame.score,
                              progress: (frame.progress * 100).rounded() / 100,
                              jetpackLeft: (frame.jetpackLeft * 50).rounded() / 50)
        if newHUD != hud {
            hud = newHUD
        }
    }

    /// Додає точку сліду, коли персонаж відлетів достатньо далеко від попередньої.
    private func updateTrail() {
        guard let player = round.session?.player else {
            trail = []
            return
        }
        let point = GameFrame.TrailPoint(x: player.position.x,
                                         y: player.position.y + player.width * 0.55)
        if let last = trail.last {
            // перехід через край світу — слід не тягнеться через увесь екран
            if abs(point.x - last.x) > GameConfig.worldWidth / 2 {
                trail = []
            } else if hypot(point.x - last.x, point.y - last.y) < Self.trailSpacing {
                return
            }
        }
        trail.append(point)
        if trail.count > Self.trailLength {
            trail.removeFirst(trail.count - Self.trailLength)
        }
    }

    private func makeFrame() -> GameFrame {
        guard let session = round.session else { return GameFrame() }
        let player = session.player
        let cameraBottom = session.maxHeight - Self.cameraOffset
        // у кадр потрапляє лише те, що видно на екрані: менше роботи для малювання
        let visible = (cameraBottom - Self.cullingMargin)...(cameraBottom + Self.visibleWorldHeight + Self.cullingMargin)

        return GameFrame(
            platforms: session.platforms
                .filter { visible.contains($0.position.y) }
                .map { platform in
                    GameFrame.PlatformSprite(id: platform.id,
                                             x: platform.position.x,
                                             y: platform.position.y,
                                             width: platform.width,
                                             type: platform.type,
                                             isBroken: platform.isBroken,
                                             isCracked: platform.isCracked)
                },
            pickups: session.pickups
                .filter { !$0.isCollected && visible.contains($0.position.y) }
                .map { GameFrame.PickupSprite(id: $0.id, kind: $0.kind,
                                              x: $0.position.x, y: $0.position.y) },
            playerX: player.position.x,
            playerY: player.position.y,
            playerWidth: player.width,
            isFalling: player.isFalling,
            trail: trail,
            jetpackLeft: session.hasJetpack ? session.jetpackTimeLeft / jetpackDuration : 0,
            // камера не опускається: тримається за найвищою точкою гравця
            cameraBottom: cameraBottom,
            score: session.score,
            progress: session.progress
        )
    }
}
