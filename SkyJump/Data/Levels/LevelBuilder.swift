import Foundation

/// Builder рівня: платформи додаються по одній, а `build()` збирає готовий масив.
///
/// Builder бере на себе те, що раніше кожен клієнт робив сам:
/// - призначає id по порядку висоти;
/// - тримає платформу в межах ігрового світу;
/// - підставляє ширину платформи.
///
/// Кожен виклик повертає нову копію, тому виклики можна писати ланцюжком.
struct LevelBuilder {
    private struct Draft {
        let x: Double
        let y: Double
        let type: PlatformType
    }

    private let worldWidth: Double
    private let platformWidth: Double
    private var drafts: [Draft] = []

    init(worldWidth: Double = GameConfig.worldWidth,
         platformWidth: Double = GameConfig.platformWidth) {
        self.worldWidth = worldWidth
        self.platformWidth = platformWidth
    }

    /// Додає платформу: x — лівий край, y — висота верхньої поверхні.
    func platform(_ type: PlatformType = .normal, x: Double, y: Double) -> LevelBuilder {
        var copy = self
        copy.drafts.append(Draft(x: x, y: y, type: type))
        return copy
    }

    /// Збирає рівень: сортує платформи знизу вгору і призначає id 0, 1, 2…
    func build() -> [Platform] {
        let maxX = max(worldWidth - platformWidth, 0)

        return drafts.enumerated()
            .sorted { lhs, rhs in
                // за однакової висоти зберігаємо порядок додавання
                (lhs.element.y, lhs.offset) < (rhs.element.y, rhs.offset)
            }
            .map(\.element)
            .enumerated()
            .map { id, draft in
                Platform(id: id,
                         x: min(max(draft.x, 0), maxX),
                         y: draft.y,
                         type: draft.type,
                         width: platformWidth)
            }
    }
}
