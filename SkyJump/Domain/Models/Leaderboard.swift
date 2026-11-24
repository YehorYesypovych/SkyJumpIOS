import Foundation

// Моделі відповіді сервера `nonisolated`: їх декодує мережевий компонент поза головним потоком.

/// Запис таблиці лідерів нескінченного режиму.
nonisolated struct LeaderboardEntry: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let player: String
    let score: Int
    let theme: String          // WorldTheme.rawValue
    let createdAt: Date        // ISO 8601
}

/// Рахунок, який надсилається на сервер.
nonisolated struct ScoreSubmission: Codable, Equatable, Sendable {
    let player: String
    let score: Int
    let theme: String
}

/// Відповідь сервера на надсилання рахунку.
nonisolated struct SubmitResult: Decodable, Equatable, Sendable {
    let entry: LeaderboardEntry
    let rank: Int              // місце в таблиці, з 1
}
