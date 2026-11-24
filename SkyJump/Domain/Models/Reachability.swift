import Foundation

/// Як розставляти платформи, щоб рівень можна було пройти.
///
/// Персонаж стрибає на ~187 одиниць угору і за час стрибка (~0,8 с до наступної платформи)
/// зсувається вбік на ~220 одиниць. Тому:
/// - відстань по вертикалі між сусідніми платформами — не більше `maxVerticalGap`;
/// - центр наступної платформи — не далі `maxHorizontalGap` від попередньої
///   (персонаж ще й може зрізати шлях через край світу — так навіть ближче).
enum Reachability {
    static let maxVerticalGap = 150.0
    static let maxHorizontalGap = 150.0

    /// Відстань між двома точками по горизонталі з урахуванням переходу через край світу.
    static func wrappedDistance(_ a: Double, _ b: Double, worldWidth: Double = GameConfig.worldWidth) -> Double {
        let direct = abs(a - b).truncatingRemainder(dividingBy: worldWidth)
        return min(direct, worldWidth - direct)
    }

    /// Лівий край наступної платформи: її центр не далі maxGap від центру попередньої.
    static func nextPlatformX<Generator: RandomNumberGenerator>(after previousX: Double,
                                                                maxGap: Double = maxHorizontalGap,
                                                                using generator: inout Generator) -> Double {
        let width = GameConfig.platformWidth
        let worldWidth = GameConfig.worldWidth
        let previousCenter = previousX + width / 2
        let shift = Double.random(in: -maxGap...maxGap, using: &generator)

        // платформа цілком на екрані; обмеження зсуває центр лише ближче до попередньої,
        // тож відстань ніколи не перевищує maxGap
        let center = min(max(previousCenter + shift, width / 2), worldWidth - width / 2)
        return center - width / 2
    }
}
