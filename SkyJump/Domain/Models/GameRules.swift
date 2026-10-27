import Foundation

/// Правила гри: фізика стрибка і межа падіння.
/// Передаються через init у GameSession, Player і стратегії приземлення,
/// тому для іншого рівня складності чи тесту достатньо створити інший GameRules.
struct GameRules {
    let gravity: Double            // прискорення вільного падіння (px/s²)
    let jumpVelocity: Double       // швидкість звичайного стрибка (px/s)
    let springMultiplier: Double   // у скільки разів пружина підсилює стрибок
    let screenHeight: Double       // висота видимої області: нижче — гравець падає

    static let standard = GameRules(gravity: -1500,
                                    jumpVelocity: 750,
                                    springMultiplier: 1.6,
                                    screenHeight: 700)
}
