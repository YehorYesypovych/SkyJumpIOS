import Foundation

/// Одна ігрова сесія: гравець + колекція платформ + рахунок.
final class GameSession {
    let player: Player
    private(set) var platforms: [Platform]
    private(set) var maxHeight: Double = 0
    private(set) var brokenPlatformsCount = 0
    private(set) var elapsedTime: Double = 0
    private(set) var log: [String] = []

    var score: Int { Int(maxHeight) }

    /// Найвища платформа — Optional, бо масив може бути порожнім.
    var highestPlatform: Platform? {
        platforms.max { $0.position.y < $1.position.y }
    }

    init(playerName: String, platforms: [Platform]) {
        self.platforms = platforms

        // Безпечне розгортання optional: ставимо гравця на першу платформу, якщо вона є
        let start: Vector2
        if let firstPlatform = platforms.first {
            start = Vector2(x: firstPlatform.position.x + firstPlatform.width / 2,
                            y: firstPlatform.position.y)
        } else {
            start = Vector2(x: GameConfig.worldWidth / 2, y: 0)
        }
        self.player = Player(name: playerName, startPosition: start)
        addLog("Старт: \(playerName), платформ на рівні: \(platforms.count)")
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
            addLog("Гравець впав. Гру закінчено")
        }
    }

    /// Запуск симуляції на заданий час (поки гравець живий).
    func run(duration: Double, deltaTime: Double = 1.0 / 60.0) {
        while elapsedTime < duration && player.isAlive {
            step(deltaTime: deltaTime)
        }
        addLog("Симуляцію завершено")
    }

    func summary() -> String {
        let status = player.isAlive ? "у грі" : "впав"
        let topPlatformInfo = highestPlatform.map { "\(Int($0.position.y))" } ?? "немає"
        let typesLeft = Dictionary(grouping: platforms, by: { $0.type.title })
            .map { "\($0.key): \($0.value.count)" }
            .sorted()
            .joined(separator: ", ")

        return """
        Гравець: \(player.name) (\(status))
        Рахунок (макс. висота): \(score)
        Стрибків: \(player.jumpsCount), зламано платформ: \(brokenPlatformsCount)
        Найвища платформа: \(topPlatformInfo)
        Залишилось платформ: \(typesLeft.isEmpty ? "немає" : typesLeft)
        """
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

        if let jumpVelocity = platform.type.jumpVelocity {
            player.jump(velocity: jumpVelocity)
            addLog("Стрибок з платформи #\(platform.id) (\(platform.type.title)) на висоті \(Int(platform.position.y))")
        } else {
            platforms[index].breakPlatform()
            brokenPlatformsCount += 1
            addLog("Платформа #\(platform.id) зламалась, гравець падає далі")
        }
    }

    private func removePlatformsBelowScreen() {
        let bottomEdge = maxHeight - GameConfig.screenHeight
        let countBefore = platforms.count
        platforms.removeAll { $0.position.y < bottomEdge }

        let removed = countBefore - platforms.count
        if removed > 0 {
            addLog("Прибрано платформ нижче екрана: \(removed)")
        }
    }

    private func addLog(_ message: String) {
        log.append("[\(String(format: "%5.2f", elapsedTime)) с] \(message)")
    }
}
