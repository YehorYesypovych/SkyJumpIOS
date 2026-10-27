import Foundation

/// Розміри світу та об'єктів. Правила гри (фізика стрибка) — у GameRules.
enum GameConfig {
    static let worldWidth: Double = 400        // ширина ігрового світу (умовні пікселі)
    static let horizontalSpeed: Double = 200   // швидкість руху вліво/вправо
    static let movingPlatformSpeed: Double = 60
    static let platformWidth: Double = 80
    static let playerWidth: Double = 40
}

/// Точка / вектор на площині. Struct — тип-значення: при присвоєнні копіюється.
struct Vector2 {
    var x: Double
    var y: Double

    static let zero = Vector2(x: 0, y: 0)
}
