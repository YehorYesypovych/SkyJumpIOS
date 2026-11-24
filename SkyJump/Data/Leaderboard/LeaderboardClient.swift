import Foundation

/// Клієнт власного сервера таблиці лідерів (`server/index.js`) на мережевому компоненті.
///
/// Сам не працює з URLSession: збирає `HTTPRequest` і віддає його `HTTPClient`, який перевіряє
/// HTTP-статус і декодує JSON. Помилки (`NetworkError`) прокидаються далі без змін.
struct LeaderboardClient: LeaderboardProviding {
    static let defaultLimit = 20
    static let limitRange = 1...100

    private let http: any HTTPClient
    private let encoder: JSONEncoder

    init(http: any HTTPClient, encoder: JSONEncoder = .skyJump) {
        self.http = http
        self.encoder = encoder
    }

    /// `GET /api/leaderboard?limit=` → `{"entries":[…]}`.
    func topScores(limit: Int) async throws -> [LeaderboardEntry] {
        let response = try await http.send(Self.topScoresRequest(limit: limit), as: LeaderboardResponseDTO.self)
        return response.entries.map(\.model)
    }

    /// `POST /api/scores` з JSON-тілом → `{"entry":{…},"rank":N}`.
    func submit(_ submission: ScoreSubmission) async throws -> SubmitResult {
        let response = try await http.send(try submitRequest(submission), as: SubmitResultDTO.self)
        return SubmitResult(entry: response.entry.model, rank: response.rank)
    }

    // MARK: - Запити (окремо, щоб перевірити їх у тестах)

    static func topScoresRequest(limit: Int) -> HTTPRequest {
        let clamped = min(max(limit, limitRange.lowerBound), limitRange.upperBound)
        return HTTPRequest(method: .get,
                           path: "/api/leaderboard",
                           query: [URLQueryItem(name: "limit", value: String(clamped))])
    }

    func submitRequest(_ submission: ScoreSubmission) throws -> HTTPRequest {
        HTTPRequest(method: .post,
                    path: "/api/scores",
                    headers: ["Content-Type": "application/json"],
                    body: try encoder.encode(submission))
    }
}

// MARK: - Формат відповіді сервера

// DTO — `nonisolated`: мережевий компонент декодує відповідь поза головним актором,
// тому відповідність `Decodable` не може бути прив'язана до MainActor (типова ізоляція проєкту).
// Після декодування дані перетворюються на моделі домену.

/// Відповідь `GET /api/leaderboard`.
nonisolated struct LeaderboardResponseDTO: Decodable, Sendable {
    let entries: [LeaderboardEntryDTO]
}

/// Відповідь `POST /api/scores`.
nonisolated struct SubmitResultDTO: Decodable, Sendable {
    let entry: LeaderboardEntryDTO
    let rank: Int
}

/// Запис таблиці у форматі сервера.
nonisolated struct LeaderboardEntryDTO: Decodable, Sendable {
    let id: String
    let player: String
    let score: Int
    let theme: String
    let createdAt: Date
}

extension LeaderboardEntryDTO {
    var model: LeaderboardEntry {
        LeaderboardEntry(id: id, player: player, score: score, theme: theme, createdAt: createdAt)
    }
}
