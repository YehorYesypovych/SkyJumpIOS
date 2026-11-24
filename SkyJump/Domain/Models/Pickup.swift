import Foundation

/// Бонус, який лежить на платформі й підбирається, коли гравець його торкається.
struct Pickup: Identifiable, Equatable {
    enum Kind: String {
        case jetpack
    }

    let id: Int
    let kind: Kind
    let position: Vector2          // центр по x, низ бонуса по y (стоїть на платформі)
    private(set) var isCollected = false

    init(id: Int, kind: Kind, x: Double, y: Double) {
        self.id = id
        self.kind = kind
        self.position = Vector2(x: x, y: y)
    }

    mutating func collect() {
        isCollected = true
    }

    /// Чи торкається гравець бонуса: x — центр гравця, feetY — рівень його ніг.
    func isTouched(byPlayerAt x: Double, feetY: Double) -> Bool {
        abs(x - position.x) <= GameConfig.playerWidth / 2 + 12
            && position.y >= feetY - 30
            && position.y <= feetY + 50
    }
}
