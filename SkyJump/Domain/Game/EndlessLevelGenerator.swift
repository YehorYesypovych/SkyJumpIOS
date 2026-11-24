import Foundation

/// Нескінченний рівень: платформи з'являються вище, ніж бачить гравець, і з висотою
/// стають рідшими й хитрішими. Відстань між платформами завжди менша за висоту стрибка,
/// тож рівень лишається прохідним.
final class EndlessLevelGenerator {
    private var generator: SeededRandomGenerator
    private var nextPlatformID = 0
    private var nextPickupID = 0
    private var platformsSinceJetpack = 0
    /// Висота найвищої вже створеної платформи.
    private(set) var topHeight: Double = 0

    /// Наперед генерується стільки висоти над гравцем.
    static let lookahead = 1_500.0

    init(seed: UInt64) {
        generator = SeededRandomGenerator(seed: seed)
    }

    /// Відстань до наступної платформи: від 95 до 150 (стрибок — ~187).
    static func step(atHeight height: Double) -> Double {
        95 + min(height / 150, 55)
    }

    /// Стартова платформа по центру і перші платформи над нею.
    func start() -> (platforms: [Platform], pickups: [Pickup]) {
        let first = Platform(id: nextPlatformID, x: 160, y: 0)
        nextPlatformID += 1
        topHeight = 0
        let rest = extend(upTo: Self.lookahead)
        return ([first] + rest.platforms, rest.pickups)
    }

    /// Нові платформи й бонуси до висоти height (якщо їх там ще немає).
    func extend(upTo height: Double) -> (platforms: [Platform], pickups: [Pickup]) {
        var platforms: [Platform] = []
        var pickups: [Pickup] = []
        let maxX = GameConfig.worldWidth - GameConfig.platformWidth

        while topHeight < height {
            let y = topHeight + Self.step(atHeight: topHeight)
            let type = randomType(atHeight: y)
            let x = Double.random(in: 0...maxX, using: &generator)
            let platform = Platform(id: nextPlatformID, x: x, y: y, type: type)
            nextPlatformID += 1
            platforms.append(platform)
            topHeight = y

            // джетпак приблизно раз на 25 платформ, лише на звичайній і не на самому старті
            platformsSinceJetpack += 1
            if type == .normal, y > 800, platformsSinceJetpack >= 25 {
                platformsSinceJetpack = 0
                pickups.append(Pickup(id: nextPickupID, kind: .jetpack,
                                      x: x + GameConfig.platformWidth / 2, y: y))
                nextPickupID += 1
            }
        }
        return (platforms, pickups)
    }

    /// Тип платформи: що вище, то більше рухомих і ламких, але звичайні лишаються основою.
    private func randomType(atHeight height: Double) -> PlatformType {
        let roll = Double.random(in: 0..<1, using: &generator)
        let difficulty = min(height / 6_000, 1)          // 0 біля землі, 1 — високо
        let moving = 0.08 + 0.17 * difficulty
        let breakable = height < 1_000 ? 0 : 0.05 + 0.15 * difficulty
        let spring = 0.07
        if roll < moving { return .moving }
        if roll < moving + breakable { return .breakable }
        if roll < moving + breakable + spring { return .spring }
        return .normal
    }
}
