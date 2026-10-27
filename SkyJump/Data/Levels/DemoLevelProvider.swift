import Foundation

/// Фіксований рівень для демонстрації: результат однаковий при кожному запуску.
struct DemoLevelProvider: LevelProviding {
    func makeLevel() -> [Platform] {
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
}
