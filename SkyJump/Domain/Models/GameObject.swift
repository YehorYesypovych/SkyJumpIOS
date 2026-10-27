import Foundation

/// Спільний контракт для всіх об'єктів на ігровому полі.
/// Його реалізують і структура Platform, і клас Player.
protocol GameObject {
    var position: Vector2 { get set }
    var width: Double { get }

    /// Оновлення стану об'єкта за проміжок часу deltaTime (у секундах).
    mutating func update(deltaTime: Double)
}

extension GameObject {
    /// Реалізація за замовчуванням: чи потрапляє координата x на об'єкт.
    func contains(x: Double) -> Bool {
        x >= position.x && x <= position.x + width
    }
}
