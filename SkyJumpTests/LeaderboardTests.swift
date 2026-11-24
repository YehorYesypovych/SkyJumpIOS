import Foundation
import Testing
@testable import SkyJump

// MARK: - Тестові дублі

/// Мережевий компонент без мережі: запам'ятовує запити і декодує заготовлену відповідь
/// тим самим декодером, що й справжній клієнт.
final class RecordingHTTPClient: HTTPClient {
    private(set) var requests: [HTTPRequest] = []
    var response: Result<Data, NetworkError>

    init(json: String) {
        response = .success(Data(json.utf8))
    }

    init(error: NetworkError) {
        response = .failure(error)
    }

    func send<T: Decodable & Sendable>(_ request: HTTPRequest, as type: T.Type) async throws -> T {
        requests.append(request)
        let data = try response.get()
        do {
            return try JSONDecoder.skyJump.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(URLSessionHTTPClient.describe(error))
        }
    }
}

/// Таблиця лідерів із заготовленими відповідями; кожен виклик topScores бере наступну.
final class ScriptedLeaderboard: LeaderboardProviding {
    private var topResults: [Result<[LeaderboardEntry], NetworkError>]
    var submitResult: Result<SubmitResult, NetworkError>
    private(set) var topCalls = 0
    private(set) var submissions: [ScoreSubmission] = []

    init(_ topResults: Result<[LeaderboardEntry], NetworkError>...,
         submitResult: Result<SubmitResult, NetworkError> = .failure(.httpStatus(500))) {
        self.topResults = topResults
        self.submitResult = submitResult
    }

    func topScores(limit: Int) async throws -> [LeaderboardEntry] {
        topCalls += 1
        let result = topResults.count > 1 ? topResults.removeFirst() : topResults[0]
        return try result.get()
    }

    func submit(_ submission: ScoreSubmission) async throws -> SubmitResult {
        submissions.append(submission)
        return try submitResult.get()
    }
}

private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "tests.leaderboard.\(UUID().uuidString)")!
}

private func entry(_ id: String, _ player: String, _ score: Int, theme: String = "neonBeach") -> LeaderboardEntry {
    LeaderboardEntry(id: id, player: player, score: score, theme: theme,
                     createdAt: Date(timeIntervalSince1970: 1_800_000_000))
}

// MARK: - Формат відповіді і клієнт

@MainActor
struct LeaderboardClientTests {

    static let entriesJSON = """
    {"entries":[
      {"id":"a1","player":"Kolya","score":4820,"theme":"noirCity","createdAt":"2026-11-24T20:28:06Z"},
      {"id":"b2","player":"Єгор","score":1200,"theme":"reef","createdAt":"2026-11-24T21:00:00Z"}
    ]}
    """

    static let submitJSON = """
    {"entry":{"id":"c3","player":"Doodler","score":1500,"theme":"neonBeach","createdAt":"2026-11-24T20:30:00Z"},"rank":2}
    """

    @Test func decodesEntriesWithISO8601Date() throws {
        let response = try JSONDecoder.skyJump.decode(LeaderboardResponseDTO.self, from: Data(Self.entriesJSON.utf8))
        let entries = response.entries.map(\.model)

        #expect(entries.map(\.player) == ["Kolya", "Єгор"])
        #expect(entries.map(\.score) == [4820, 1200])
        #expect(entries[0].theme == "noirCity")
        #expect(entries[0].createdAt == ISO8601DateFormatter().date(from: "2026-11-24T20:28:06Z"))
    }

    @Test func decodesSubmitResult() throws {
        let result = try JSONDecoder.skyJump.decode(SubmitResultDTO.self, from: Data(Self.submitJSON.utf8))

        #expect(result.rank == 2)
        #expect(result.entry.model.player == "Doodler")
        #expect(result.entry.model.createdAt == ISO8601DateFormatter().date(from: "2026-11-24T20:30:00Z"))
    }

    @Test func mismatchedResponseBecomesDecodingError() async {
        // немає createdAt і score — рядок замість числа
        let http = RecordingHTTPClient(json: #"{"entries":[{"id":"1","player":"X","score":"many","theme":"reef"}]}"#)
        let client = LeaderboardClient(http: http)

        await #expect {
            _ = try await client.topScores(limit: 5)
        } throws: { error in
            if case .decoding = error as? NetworkError { return true }
            return false
        }
    }

    @Test func topScoresSendsGetWithLimit() async throws {
        let http = RecordingHTTPClient(json: Self.entriesJSON)
        let client = LeaderboardClient(http: http)

        let entries = try await client.topScores(limit: 5)

        #expect(entries.count == 2)
        let request = try #require(http.requests.first)
        #expect(request.method == .get)
        #expect(request.path == "/api/leaderboard")
        #expect(request.query == [URLQueryItem(name: "limit", value: "5")])
        #expect(request.body == nil)
    }

    @Test func limitIsClampedAndSimulateIsAdded() {
        #expect(LeaderboardClient.topScoresRequest(limit: 0).query.first?.value == "1")
        #expect(LeaderboardClient.topScoresRequest(limit: 500).query.first?.value == "100")

        let simulated = LeaderboardClient.topScoresRequest(limit: 20, simulate: "slow")
        #expect(simulated.query.contains(URLQueryItem(name: "simulate", value: "slow")))
    }

    @Test func submitSendsJSONBody() async throws {
        let http = RecordingHTTPClient(json: Self.submitJSON)
        let client = LeaderboardClient(http: http)

        let result = try await client.submit(ScoreSubmission(player: "Doodler", score: 1500, theme: "neonBeach"))

        #expect(result.rank == 2)
        #expect(result.entry.id == "c3")
        let request = try #require(http.requests.first)
        #expect(request.method == .post)
        #expect(request.path == "/api/scores")
        #expect(request.headers["Content-Type"] == "application/json")
        let body = try #require(request.body)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["player"] as? String == "Doodler")
        #expect(json["score"] as? Int == 1500)
        #expect(json["theme"] as? String == "neonBeach")
    }

    @Test func httpErrorIsPassedThrough() async {
        let client = LeaderboardClient(http: RecordingHTTPClient(error: .httpStatus(500)))

        await #expect(throws: NetworkError.httpStatus(500)) {
            _ = try await client.topScores(limit: 20)
        }
    }
}

// MARK: - Екран «Лідери»

@MainActor
struct LeaderboardViewModelTests {

    private func makeViewModel(_ provider: ScriptedLeaderboard,
                               profile: PlayerProfile = PlayerProfile(defaults: freshDefaults()),
                               reporter: LeaderboardScoreReporter? = nil) -> LeaderboardViewModel {
        LeaderboardViewModel(provider: provider, profile: profile, reporter: reporter)
    }

    @Test func loadsEntries() async {
        let entries = [entry("1", "Kolya", 900), entry("2", "Єгор", 500)]
        let viewModel = makeViewModel(ScriptedLeaderboard(.success(entries)))
        #expect(viewModel.state == .idle)

        await viewModel.load()

        #expect(viewModel.state == .loaded(entries))
    }

    @Test func emptyListIsEmptyStateNotError() async {
        let viewModel = makeViewModel(ScriptedLeaderboard(.success([])))
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func failuresHaveDifferentMessages() async {
        func message(for error: NetworkError) async -> String? {
            let viewModel = makeViewModel(ScriptedLeaderboard(.failure(error)))
            await viewModel.load()
            if case .failed(let message) = viewModel.state { return message }
            return nil
        }
        let offline = await message(for: .transport(.notConnectedToInternet))
        let serverDown = await message(for: .transport(.cannotConnectToHost))
        let http500 = await message(for: .httpStatus(500))
        let broken = await message(for: .decoding("немає поля"))

        let all = [offline, serverDown, http500, broken].compactMap { $0 }
        #expect(all.count == 4)
        #expect(Set(all).count == 4)
        #expect(http500?.contains("500") == true)
        #expect(serverDown?.contains("node server/index.js") == true)
    }

    @Test func retryAfterFailureShowsData() async {
        let entries = [entry("1", "Kolya", 900)]
        let provider = ScriptedLeaderboard(.failure(.transport(.cannotConnectToHost)), .success(entries))
        let viewModel = makeViewModel(provider)

        await viewModel.load()
        guard case .failed = viewModel.state else {
            Issue.record("Перша спроба має завершитися помилкою")
            return
        }
        await viewModel.load()

        #expect(viewModel.state == .loaded(entries))
        #expect(provider.topCalls == 2)
    }

    @Test func loadIfNeededLoadsOnce() async {
        let provider = ScriptedLeaderboard(.success([entry("1", "Kolya", 900)]))
        let viewModel = makeViewModel(provider)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(provider.topCalls == 1)
    }

    @Test func ownEntriesAreHighlighted() {
        let profile = PlayerProfile(defaults: freshDefaults())
        profile.update(nickname: "Єгор")
        let viewModel = makeViewModel(ScriptedLeaderboard(.success([])), profile: profile)

        #expect(viewModel.isOwn(entry("1", "Єгор", 100)))
        #expect(!viewModel.isOwn(entry("2", "Kolya", 100)))
    }

    @Test func invalidNicknameIsNotSaved() {
        let profile = PlayerProfile(defaults: freshDefaults())
        let viewModel = makeViewModel(ScriptedLeaderboard(.success([])), profile: profile)

        viewModel.nicknameDraft = "   "
        #expect(!viewModel.canSaveNickname)
        viewModel.saveNickname()
        #expect(viewModel.nicknameMessage != nil)
        #expect(profile.nickname == PlayerProfile.defaultNickname)

        viewModel.nicknameDraft = "  SkyKing "
        viewModel.saveNickname()
        #expect(viewModel.nicknameMessage == nil)
        #expect(profile.nickname == "SkyKing")
        #expect(viewModel.nicknameDraft == "SkyKing")
    }
}

// MARK: - Нік і надсилання рахунку

@MainActor
struct ScoreReporterTests {

    @Test func profileValidatesAndPersistsNickname() {
        let defaults = freshDefaults()
        let profile = PlayerProfile(defaults: defaults)
        #expect(profile.nickname == "Doodler")

        #expect(!profile.update(nickname: ""))
        #expect(!profile.update(nickname: String(repeating: "x", count: 21)))
        #expect(profile.update(nickname: "  Kolya  "))
        #expect(profile.nickname == "Kolya")

        #expect(PlayerProfile(defaults: defaults).nickname == "Kolya")
    }

    @Test func reportSendsNicknameAndThemeAndKeepsRank() async {
        let result = SubmitResult(entry: entry("x", "Єгор", 2500, theme: "reef"), rank: 3)
        let provider = ScriptedLeaderboard(.success([]), submitResult: .success(result))
        let profile = PlayerProfile(defaults: freshDefaults())
        profile.update(nickname: "Єгор")
        let cosmetics = CosmeticsSettings(defaults: freshDefaults())
        cosmetics.theme = .reef
        let reporter = LeaderboardScoreReporter(provider: provider, profile: profile, cosmetics: cosmetics)

        reporter.report(score: 2500)
        #expect(reporter.status == .sending(score: 2500))
        await reporter.pendingTask?.value

        #expect(provider.submissions == [ScoreSubmission(player: "Єгор", score: 2500, theme: "reef")])
        #expect(reporter.lastResult?.rank == 3)

        let viewModel = LeaderboardViewModel(provider: provider, profile: profile, reporter: reporter)
        #expect(viewModel.lastSubmissionText == "Твій рахунок 2500 — 3 місце")
        #expect(viewModel.isOwn(entry("x", "інший нік", 2500)))
    }

    @Test func zeroScoreIsNotSent() async {
        let provider = ScriptedLeaderboard(.success([]))
        let reporter = LeaderboardScoreReporter(provider: provider,
                                                profile: PlayerProfile(defaults: freshDefaults()),
                                                cosmetics: CosmeticsSettings(defaults: freshDefaults()))
        reporter.report(score: 0)
        await reporter.pendingTask?.value

        #expect(provider.submissions.isEmpty)
        #expect(reporter.status == .idle)
    }

    @Test func failedSubmissionIsShown() async {
        let provider = ScriptedLeaderboard(.success([]), submitResult: .failure(.transport(.cannotConnectToHost)))
        let reporter = LeaderboardScoreReporter(provider: provider,
                                                profile: PlayerProfile(defaults: freshDefaults()),
                                                cosmetics: CosmeticsSettings(defaults: freshDefaults()))
        reporter.report(score: 700)
        await reporter.pendingTask?.value

        #expect(reporter.status == .failed(score: 700, error: .transport(.cannotConnectToHost)))
        let viewModel = LeaderboardViewModel(provider: provider, reporter: reporter)
        #expect(viewModel.lastSubmissionFailed)
        #expect(viewModel.lastSubmissionText?.hasPrefix("Рахунок 700 не надіслано") == true)
    }

    @Test func endlessGameReportsOnceWhenItEnds() {
        // крихітні стрибки (≈3 одиниці) і постійний рух управо: гравець сходить зі стартової платформи
        // на висоті 0, нижче платформ немає — гра гарантовано закінчується падінням
        let tinyJumps = GameRules(gravity: -1500, jumpVelocity: 100, springMultiplier: 1, screenHeight: 700)
        let reporter = SpyScoreReporter()
        let navigator = SpyNavigator()
        let viewModel = GameplayViewModel(mode: .endless, library: LevelLibrary(),
                                          scoreStore: InMemoryScoreStore(), endlessScores: InMemoryScoreStore(),
                                          navigator: navigator, scoreReporter: reporter, rules: tinyJumps)
        viewModel.start()
        viewModel.setInput(1)
        for _ in 0..<(60 * 10) {
            viewModel.tick(deltaTime: 1.0 / 60.0)
        }

        #expect(viewModel.outcome == .lost)
        #expect(reporter.reportedScores.count == 1)
    }
}
