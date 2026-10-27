import Foundation

/// Одна ігрова сесія: гравець + колекція платформ + рахунок.
/// Subject для Observer: про все, що відбувається, повідомляє спостерігачам через GameEvent.
final class GameSession {
    let player: Player
    private(set) var platforms: [Platform]
    private(set) var maxHeight: Double = 0
    private(set) var brokenPlatformsCount = 0
    private(set) var elapsedTime: Double = 0
    private let landingStrategies: [PlatformType: LandingStrategy]
    private var observers: [WeakObserver] = []

    var score: Int { Int(maxHeight) }

    /// Найвища платформа — Optional, бо масив може бути порожнім.
    var highestPlatform: Platform? {
        platforms.max { $0.position.y < $1.position.y }
    }

    init(playerName: String, platforms: [Platform],
         landingStrategies: [PlatformType: LandingStrategy] = LandingStrategies.standard,
         observers: [GameEventObserver] = []) {
        self.platforms = platforms
        self.landingStrategies = landingStrategies
        self.observers = observers.map { WeakObserver($0) }

        // Безпечне розгортання optional: ставимо гравця на першу платформу, якщо вона є
        let start: Vector2
        if let firstPlatform = platforms.first {
            start = Vector2(x: firstPlatform.position.x + firstPlatform.width / 2,
                            y: firstPlatform.position.y)
        } else {
            start = Vector2(x: GameConfig.worldWidth / 2, y: 0)
        }
        self.player = Player(name: playerName, startPosition: start)
        emit(.started(playerName: playerName, platformCount: platforms.count))
    }

    /// Підписує спостерігача на події сесії. Сесія тримає його слабким посиланням:
    /// жити спостерігачу чи ні, вирішує той, хто його створив.
    func addObserver(_ observer: GameEventObserver) {
        observers.append(WeakObserver(observer))
    }

    /// Один кадр гри.
    func step(deltaTime: Double, input: Double = 0) {
        guard player.isAlive else { return }
        elapsedTime += deltaTime

        player.move(direction: input)
        for index in platforms.indices {
            platforms[index].update(deltaTime: deltaTime)
        }

        let previousY = player.position.y
        player.update(deltaTime: deltaTime)

        // Приземлення можливе лише під час падіння
        if player.isFalling, let index = landingPlatformIndex(previousY: previousY) {
            handleLanding(onPlatformAt: index)
        }

        if player.position.y > maxHeight {
            maxHeight = player.position.y
        }
        removePlatformsBelowScreen()

        if player.position.y < maxHeight - GameConfig.screenHeight {
            player.die()
            emit(.playerFell)
        }
    }

    /// Запуск симуляції на заданий час (поки гравець живий).
    func run(duration: Double, deltaTime: Double = 1.0 / 60.0) {
        while elapsedTime < duration && player.isAlive {
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
                && platform.contains(x: player.position.x)
                && previousY >= platform.position.y
                && player.position.y <= platform.position.y
        }
    }

    private func handleLanding(onPlatformAt index: Int) {
        let platform = platforms[index]
        player.position.y = platform.position.y

        // Тип без стратегії поводиться як звичайна платформа
        let strategy = landingStrategies[platform.type]
            ?? BounceLanding(velocity: GameConfig.jumpVelocity)

        switch strategy.land(player: player, on: &platforms[index]) {
        case .jumped:
            emit(.jumped(platformID: platform.id, type: platform.type, height: platform.position.y))
        case .broke:
            brokenPlatformsCount += 1
            emit(.platformBroken(platformID: platform.id))
        }
    }

    private func removePlatformsBelowScreen() {
        let bottomEdge = maxHeight - GameConfig.screenHeight
        let countBefore = platforms.count
        platforms.removeAll { $0.position.y < bottomEdge }

        let removed = countBefore - platforms.count
        if removed > 0 {
            emit(.platformsRemoved(count: removed))
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
