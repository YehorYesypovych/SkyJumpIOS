import Foundation

enum GameConfig {
    static let worldWidth: Double = 400        // ширина ігрового світу (умовні пікселі)
    static let screenHeight: Double = 700      // висота видимої області
    static let gravity: Double = -1500         // прискорення вільного падіння (px/s²)
    static let jumpVelocity: Double = 750      // швидкість звичайного стрибка (px/s)
    static let springMultiplier: Double = 1.6  // у скільки разів пружина підсилює стрибок
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
