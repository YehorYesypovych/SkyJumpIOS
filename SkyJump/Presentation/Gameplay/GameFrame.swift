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
        let isCracked: Bool
    }

    struct PickupSprite: Identifiable, Equatable {
        let id: Int
        let kind: Pickup.Kind
        let x: Double          // центр
        let y: Double          // низ
    }

    var platforms: [PlatformSprite] = []
    var pickups: [PickupSprite] = []
    var playerX: Double = GameConfig.worldWidth / 2   // центр гравця
    var playerY: Double = 0                           // рівень «ніг»
    var playerWidth: Double = GameConfig.playerWidth
    var isFalling = false
    var jetpackLeft: Double = 0    // 0…1 — скільки залишилось джетпака (0 — немає)
    var cameraBottom: Double = 0   // висота світу на нижньому краю екрана
    var score = 0
    var progress: Double = 0       // 0…1 до верхньої платформи

    static let worldWidth = GameConfig.worldWidth
}
