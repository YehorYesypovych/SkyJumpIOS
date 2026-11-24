import Foundation

/// Одна ігрова сесія: гравець + колекція платформ + рахунок.
/// Subject для Observer: про все, що відбувається, повідомляє спостерігачам через GameEvent.
final class GameSession {
    let player: Player
    private(set) var platforms: [Platform]
    private(set) var maxHeight: Double = 0
    private(set) var brokenPlatformsCount = 0
    private(set) var elapsedTime: Double = 0
    private(set) var outcome: GameOutcome = .playing
    private(set) var pickups: [Pickup]
    /// Скільки секунд ще працює джетпак (0 — не працює).
    private(set) var jetpackTimeLeft: Double = 0
    /// Висота верхньої платформи рівня на момент старту (0 — платформ немає).
    let topHeight: Double
    private let rules: GameRules
    private let landingStrategies: [PlatformType: LandingStrategy]
    private var observers: [WeakObserver] = []
    /// Режим справжньої гри: досягти висоти верхньої платформи — перемога.
    /// У симуляції вимкнено, тож поведінка демо-сценарію не змінюється.
    private let completesAtTop: Bool
    /// Ширина «ніг» гравця для приземлення. 0 — лише центр (як у симуляції),
    /// у грі — частина ширини персонажа, щоб приземлення збігалося з тим, що видно на екрані.
    private let footWidth: Double

    var score: Int { Int(maxHeight) }

    var hasJetpack: Bool { jetpackTimeLeft > 0 }

    /// Прогрес до верхньої платформи: 0…1.
    var progress: Double {
        guard topHeight > 0 else { return 0 }
        return min(maxHeight / topHeight, 1)
    }

    /// Найвища платформа — Optional, бо масив може бути порожнім.
    var highestPlatform: Platform? {
        platforms.max { $0.position.y < $1.position.y }
    }

    /// landingStrategies: nil — стандартний набір за правилами rules.
    /// completesAtTop: true — гра закінчується перемогою на висоті верхньої платформи.
    init(playerName: String, platforms: [Platform],
         rules: GameRules = .standard,
         landingStrategies: [PlatformType: LandingStrategy]? = nil,
         observers: [GameEventObserver] = [],
         completesAtTop: Bool = false,
         footWidth: Double = 0,
         pickups: [Pickup] = []) {
        self.platforms = platforms
        self.pickups = pickups
        self.topHeight = platforms.map { $0.position.y }.max() ?? 0
        self.completesAtTop = completesAtTop
        self.footWidth = max(footWidth, 0)
        self.rules = rules
        self.landingStrategies = landingStrategies ?? LandingStrategies.standard(rules: rules)
        self.observers = observers.map { WeakObserver($0) }

        // Безпечне розгортання optional: ставимо гравця на першу платформу, якщо вона є
        let start: Vector2
        if let firstPlatform = platforms.first {
            start = Vector2(x: firstPlatform.position.x + firstPlatform.width / 2,
                            y: firstPlatform.position.y)
        } else {
            start = Vector2(x: GameConfig.worldWidth / 2, y: 0)
        }
        self.player = Player(name: playerName, startPosition: start, gravity: rules.gravity)
        emit(.started(playerName: playerName, platformCount: platforms.count))
    }

    /// Підписує спостерігача на події сесії. Сесія тримає його слабким посиланням:
    /// жити спостерігачу чи ні, вирішує той, хто його створив.
    func addObserver(_ observer: GameEventObserver) {
        observers.append(WeakObserver(observer))
    }

    /// Один кадр гри.
    func step(deltaTime: Double, input: Double = 0) {
        guard player.isAlive, outcome == .playing else { return }
        elapsedTime += deltaTime

        player.move(direction: input)
        for index in platforms.indices {
            platforms[index].update(deltaTime: deltaTime)
        }

        if hasJetpack {
            jetpackTimeLeft = max(jetpackTimeLeft - deltaTime, 0)
            player.fly(upwardSpeed: rules.jetpackVelocity)
        }

        let previousY = player.position.y
        player.update(deltaTime: deltaTime)

        // Приземлення можливе лише під час падіння (з джетпаком гравець летить крізь платформи)
        if !hasJetpack, player.isFalling, let index = landingPlatformIndex(previousY: previousY) {
            handleLanding(onPlatformAt: index)
        }
        collectPickups()

        if player.position.y > maxHeight {
            maxHeight = player.position.y
        }

        if completesAtTop, topHeight > 0, maxHeight >= topHeight {
            outcome = .won
            emit(.levelCompleted)
            return
        }

        removePlatformsBelowScreen()

        if player.position.y < maxHeight - rules.screenHeight {
            player.die()
            outcome = .lost
            emit(.playerFell)
        }
    }

    /// Запуск симуляції на заданий час (поки гравець живий).
    func run(duration: Double, deltaTime: Double = 1.0 / 60.0) {
        while elapsedTime < duration && player.isAlive && outcome == .playing {
            step(deltaTime: deltaTime)
        }
        emit(.finished)
    }

    /// Дані підсумку без форматування (текст формує Presentation).
    func makeSummary() -> GameSummary {
        let platformsLeft = Dictionary(grouping: platforms, by: { $0.type })
            .mapValues { $0.count }

        return GameSummary(playerName: player.name,
                           isAlive: player.isAlive,
                           score: score,
                           jumpsCount: player.jumpsCount,
                           brokenPlatformsCount: brokenPlatformsCount,
                           highestPlatformY: highestPlatform?.position.y,
                           platformsLeft: platformsLeft)
    }

    // MARK: - Приватна логіка

    /// Індекс платформи, яку гравець перетнув згори вниз за останній кадр, або nil.
    private func landingPlatformIndex(previousY: Double) -> Int? {
        platforms.firstIndex { platform in
            !platform.isBroken
                && isStanding(on: platform)
                && previousY >= platform.position.y
                && player.position.y <= platform.position.y
        }
    }

    /// Чи потрапляють «ноги» гравця на платформу по горизонталі.
    private func isStanding(on platform: Platform) -> Bool {
        guard footWidth > 0 else { return platform.contains(x: player.position.x) }
        let half = footWidth / 2
        return player.position.x + half >= platform.position.x
            && player.position.x - half <= platform.position.x + platform.width
    }

    private func handleLanding(onPlatformAt index: Int) {
        let platform = platforms[index]
        player.position.y = platform.position.y

        // Тип без стратегії поводиться як звичайна платформа
        let strategy = landingStrategies[platform.type]
            ?? BounceLanding(velocity: rules.jumpVelocity)

        switch strategy.land(player: player, on: &platforms[index]) {
        case .jumped:
            emit(.jumped(platformID: platform.id, type: platform.type, height: platform.position.y))
        case .broke:
            brokenPlatformsCount += 1
            emit(.platformBroken(platformID: platform.id))
        }
    }

    private func removePlatformsBelowScreen() {
        let bottomEdge = maxHeight - rules.screenHeight
        let countBefore = platforms.count
        platforms.removeAll { $0.position.y < bottomEdge }

        let removed = countBefore - platforms.count
        if removed > 0 {
            emit(.platformsRemoved(count: removed))
        }
        pickups.removeAll { $0.position.y < bottomEdge }
    }

    private func collectPickups() {
        for index in pickups.indices where !pickups[index].isCollected {
            guard pickups[index].isTouched(byPlayerAt: player.position.x, feetY: player.position.y) else { continue }
            pickups[index].collect()
            switch pickups[index].kind {
            case .jetpack:
                jetpackTimeLeft = rules.jetpackDuration
                emit(.jetpackPicked)
            }
        }
    }

    private func emit(_ event: GameEvent) {
        observers.removeAll { $0.value == nil }
        for observer in observers {
            observer.value?.gameSession(didEmit: event, at: elapsedTime)
        }
    }
}

/// Слабке посилання на спостерігача, щоб сесія не утримувала його в пам'яті.
private struct WeakObserver {
    weak var value: GameEventObserver?

    init(_ value: GameEventObserver) {
        self.value = value
    }
}
