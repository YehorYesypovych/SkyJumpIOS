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
    /// Режим перевірки на сервері (`empty`, `error`, `broken`, `slow`); nil — звичайна робота.
    private let simulate: String?

    init(http: any HTTPClient, encoder: JSONEncoder = .skyJump, simulate: String? = nil) {
        self.http = http
        self.encoder = encoder
        self.simulate = simulate.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// `GET /api/leaderboard?limit=` → `{"entries":[…]}`.
    func topScores(limit: Int) async throws -> [LeaderboardEntry] {
        let request = Self.topScoresRequest(limit: limit, simulate: simulate)
        return try await http.send(request, as: LeaderboardResponse.self).entries
    }

    /// `POST /api/scores` з JSON-тілом → `{"entry":{…},"rank":N}`.
    func submit(_ submission: ScoreSubmission) async throws -> SubmitResult {
        try await http.send(try submitRequest(submission), as: SubmitResult.self)
    }

    // MARK: - Запити (окремо, щоб перевірити їх у тестах)

    static func topScoresRequest(limit: Int, simulate: String? = nil) -> HTTPRequest {
        let clamped = min(max(limit, limitRange.lowerBound), limitRange.upperBound)
        var query = [URLQueryItem(name: "limit", value: String(clamped))]
        if let simulate {
            query.append(URLQueryItem(name: "simulate", value: simulate))
        }
        return HTTPRequest(method: .get, path: "/api/leaderboard", query: query)
    }

    func submitRequest(_ submission: ScoreSubmission) throws -> HTTPRequest {
        HTTPRequest(method: .post,
                    path: "/api/scores",
                    headers: ["Content-Type": "application/json"],
                    body: try encoder.encode(submission))
    }
}

/// Обгортка відповіді `GET /api/leaderboard`. `nonisolated`, як і моделі домену:
/// мережевий компонент декодує відповідь поза головним потоком.
nonisolated struct LeaderboardResponse: Decodable, Sendable {
    let entries: [LeaderboardEntry]
}
