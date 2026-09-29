import Foundation

/// Створення рівнів.
enum LevelFactory {
    /// Фіксований рівень для демонстрації: результат однаковий при кожному запуску.
    static func makeDemoLevel() -> [Platform] {
        let layout: [(y: Double, x: Double, type: PlatformType)] = [
            (0, 160, .normal),
            (120, 140, .normal),
            (240, 170, .normal),
            (330, 150, .normal),
            (360, 160, .breakable),
            (450, 130, .spring),
            (850, 160, .normal),
            (900, 150, .moving),
            (1000, 140, .normal),
            (1110, 160, .normal)
        ]

        return layout.enumerated().map { item in
            Platform(id: item.offset,
                     x: item.element.x,
                     y: item.element.y,
                     type: item.element.type)
        }
    }

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
