import Foundation

/// Гравець — class (тип-посилання): у грі існує один гравець,
/// і всі частини програми мають працювати з тим самим об'єктом, а не з копією.
final class Player: GameObject {
    let name: String
    var position: Vector2              // x — центр гравця, y — рівень "ніг"
    let width: Double = GameConfig.playerWidth
    private(set) var velocity: Vector2 = .zero
    private(set) var isAlive = true
    private(set) var jumpsCount = 0

    /// Обчислювана властивість
    var isFalling: Bool { velocity.y < 0 }

    init(name: String, startPosition: Vector2) {
        self.name = name
        self.position = startPosition
    }

    /// Для класу вимога `mutating` з протоколу реалізується звичайним методом.
    func update(deltaTime: Double) {
        velocity.y += GameConfig.gravity * deltaTime
        position.x += velocity.x * deltaTime
        position.y += velocity.y * deltaTime

        // Як у Doodle Jump: вийшов за правий край — з'явився зліва, і навпаки
        if position.x > GameConfig.worldWidth {
            position.x = 0
        } else if position.x < 0 {
            position.x = GameConfig.worldWidth
        }
    }

    func jump(velocity jumpVelocity: Double) {
        velocity.y = jumpVelocity
        jumpsCount += 1
    }

    /// direction: -1 — вліво, 0 — стоїмо, 1 — вправо
    func move(direction: Double) {
        velocity.x = direction * GameConfig.horizontalSpeed
    }

    func die() {
        isAlive = false
    }
}
