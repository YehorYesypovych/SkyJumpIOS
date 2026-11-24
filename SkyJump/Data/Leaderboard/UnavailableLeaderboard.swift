import Foundation

/// Тимчасова таблиця лідерів до появи справжнього клієнта (частина B):
/// завжди відповідає, що сервер недоступний.
struct UnavailableLeaderboard: LeaderboardProviding {
    func topScores(limit: Int) async throws -> [LeaderboardEntry] {
        throw NetworkError.transport(.cannotConnectToHost)
    }

    func submit(_ submission: ScoreSubmission) async throws -> SubmitResult {
        throw NetworkError.transport(.cannotConnectToHost)
    }
}
