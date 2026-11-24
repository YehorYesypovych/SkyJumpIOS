import Foundation

/// Що малювати в поточному кадрі гри. Координати — у світі гри (y угору);
/// перетворення в координати екрана робить View.
struct GameFrame: Equatable {
    struct PlatformSprite: Identifiable, Equatable {
        let id: Int
        let x: Double          // лівий край
        let y: Double          // верхня поверхня
        let width: Double
        let type: PlatformType
        let isBroken: Bool
    }

    var platforms: [PlatformSprite] = []
    var playerX: Double = GameConfig.worldWidth / 2   // центр гравця
    var playerY: Double = 0                           // рівень «ніг»
    var playerWidth: Double = GameConfig.playerWidth
    var isFalling = false
    var cameraBottom: Double = 0   // висота світу на нижньому краю екрана
    var score = 0
    var progress: Double = 0       // 0…1 до верхньої платформи

    static let worldWidth = GameConfig.worldWidth
}
