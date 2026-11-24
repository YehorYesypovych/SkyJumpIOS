import Foundation

/// Сценарій режиму перевірки станів екрана «Лідери».
enum LeaderboardScenario: String, CaseIterable, Identifiable {
    case live
    case sample
    case empty
    case offline
    case serverError
    case broken
    case slow

    var id: Self { self }

    var title: String {
        switch self {
        case .live: return "Справжній сервер"
        case .sample: return "Приклад даних"
        case .empty: return "Порожня таблиця"
        case .offline: return "Немає мережі"
        case .serverError: return "HTTP 500"
        case .broken: return "Пошкоджений JSON"
        case .slow: return "Повільна відповідь"
        }
    }
}

/// Таблиця лідерів без мережі: для Preview, тестів і режиму перевірки станів.
struct StubLeaderboard: LeaderboardProviding {
    let scenario: LeaderboardScenario
    var delay: Duration = .seconds(3)

    func topScores(limit: Int) async throws -> [LeaderboardEntry] {
        switch scenario {
        case .live, .sample:
            return Array(Self.sampleEntries.prefix(limit))
        case .empty:
            return []
        case .offline:
            throw NetworkError.transport(.notConnectedToInternet)
        case .serverError:
            throw NetworkError.httpStatus(500)
        case .broken:
            throw NetworkError.decoding("немає поля «entries»")
        case .slow:
            try await Task.sleep(for: delay)
            return Array(Self.sampleEntries.prefix(limit))
        }
    }

    func submit(_ submission: ScoreSubmission) async throws -> SubmitResult {
        _ = try await topScores(limit: 1)
        let entry = LeaderboardEntry(id: UUID().uuidString, player: submission.player, score: submission.score,
                                     theme: submission.theme, createdAt: .now)
        let rank = Self.sampleEntries.filter { $0.score > submission.score }.count + 1
        return SubmitResult(entry: entry, rank: rank)
    }

    static let sampleEntries: [LeaderboardEntry] = {
        let now = Date.now
        let rows: [(String, Int, WorldTheme, Double)] = [
            ("Kolya", 4820, .noirCity, 3_600),
            ("Doodler", 3915, .neonBeach, 7_200),
            ("Єгор", 3540, .reef, 86_400),
            ("Skyler", 2210, .olympus, 172_800),
            ("PaperJet", 1475, .classic, 400_000)
        ]
        return rows.enumerated().map { index, row in
            LeaderboardEntry(id: "sample-\(index)", player: row.0, score: row.1,
                             theme: row.2.rawValue, createdAt: now.addingTimeInterval(-row.3))
        }
    }()
}
