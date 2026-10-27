import Foundation

/// Платформа — struct, бо це просте значення без власної "ідентичності":
/// сесія зберігає масив платформ і змінює їх через індекс.
struct Platform: GameObject {
    let id: Int
    var position: Vector2          // position.y — верхня поверхня платформи
    let width: Double
    let type: PlatformType
    private(set) var isBroken = false
    private var direction: Double = 1   // напрям руху для рухомої платформи

    init(id: Int, x: Double, y: Double, type: PlatformType = .normal,
         width: Double = GameConfig.platformWidth) {
        self.id = id
        self.position = Vector2(x: x, y: y)
        self.type = type
        self.width = width
    }

    mutating func update(deltaTime: Double) {
        // Рухаються лише цілі рухомі платформи
        guard type == .moving, !isBroken else { return }

        position.x += direction * GameConfig.movingPlatformSpeed * deltaTime
        if position.x <= 0 || position.x + width >= GameConfig.worldWidth {
            direction *= -1
        }
    }

    mutating func breakPlatform() {
        isBroken = true
    }
}
