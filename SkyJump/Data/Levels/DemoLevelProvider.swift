import Foundation

/// Фіксований рівень для демонстрації: результат однаковий при кожному запуску.
struct DemoLevelProvider: LevelProviding {
    func makeLevel() -> [Platform] {
        LevelBuilder()
            .platform(.normal, x: 160, y: 0)
            .platform(.normal, x: 140, y: 120)
            .platform(.normal, x: 170, y: 240)
            .platform(.normal, x: 150, y: 330)
            .platform(.breakable, x: 160, y: 360)
            .platform(.spring, x: 130, y: 450)
            .platform(.normal, x: 160, y: 850)
            .platform(.moving, x: 150, y: 900)
            .platform(.normal, x: 140, y: 1000)
            .platform(.normal, x: 160, y: 1110)
            .build()
    }
}
