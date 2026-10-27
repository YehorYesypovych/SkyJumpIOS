import Foundation

/// Рекорд у пам'яті: живе, поки працює застосунок. Підходить для Preview і тестів.
final class InMemoryScoreStore: ScoreStoring {
    private(set) var bestScore: Int

    init(bestScore: Int = 0) {
        self.bestScore = bestScore
    }

    @discardableResult
    func submit(score: Int) -> Bool {
        guard score > bestScore else { return false }
        bestScore = score
        return true
    }
}
