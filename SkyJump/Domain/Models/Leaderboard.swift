import Foundation

/// Запис таблиці лідерів нескінченного режиму.
struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: String
    let player: String
    let score: Int
    let theme: String          // WorldTheme.rawValue
    let createdAt: Date        // ISO 8601
}

/// Рахунок, який надсилається на сервер.
struct ScoreSubmission: Codable, Equatable {
    let player: String
    let score: Int
    let theme: String
}

/// Відповідь сервера на надсилання рахунку.
struct SubmitResult: Decodable, Equatable {
    let entry: LeaderboardEntry
    let rank: Int              // місце в таблиці, з 1
}
