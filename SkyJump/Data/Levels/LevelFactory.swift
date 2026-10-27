import Foundation

/// Створення випадкового рівня (демо-рівень — у DemoLevelProvider).
enum LevelFactory {
    /// Випадковий рівень
    static func makeRandomLevel(count: Int) -> [Platform] {
        var platforms: [Platform] = [Platform(id: 0, x: 160, y: 0)]
        for id in 1..<max(count, 1) {
            let type = PlatformType.allCases.randomElement() ?? .normal
            let x = Double.random(in: 0...(GameConfig.worldWidth - GameConfig.platformWidth))
            platforms.append(Platform(id: id, x: x, y: Double(id) * 110, type: type))
        }
        return platforms
    }
}
