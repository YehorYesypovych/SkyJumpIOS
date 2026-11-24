import Foundation

/// Джерело таблиці лідерів (власний сервер, у тестах і Preview — заглушка).
protocol LeaderboardProviding {
    func topScores(limit: Int) async throws -> [LeaderboardEntry]
    func submit(_ submission: ScoreSubmission) async throws -> SubmitResult
}

/// Куди віддати рахунок після нескінченної гри (сервер, у тестах — шпигун).
/// Нік і тему реалізація бере сама (профіль гравця, обраний стиль).
protocol ScoreReporting: AnyObject {
    func report(score: Int)
}
