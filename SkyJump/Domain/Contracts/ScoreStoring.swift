import Foundation

/// Сховище рекорду гравця.
protocol ScoreStoring {
    var bestScore: Int { get }

    /// Зберігає результат, якщо він кращий за рекорд.
    /// Повертає true, якщо score — новий рекорд.
    @discardableResult
    func submit(score: Int) -> Bool
}
