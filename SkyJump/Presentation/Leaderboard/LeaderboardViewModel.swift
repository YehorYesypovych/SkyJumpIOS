import Foundation
import Observation

/// ViewModel екрана «Лідери»: завантажує топ із сервера через `LeaderboardProviding`,
/// керує ніком гравця і показує результат останнього надсилання рахунку.
@Observable
final class LeaderboardViewModel {
    static let limit = 20

    private(set) var state: LoadState<[LeaderboardEntry]> = .idle
    /// Нік у полі введення (зберігається лише кнопкою / Return).
    var nicknameDraft: String
    private(set) var nicknameMessage: String?
    /// Режим перевірки станів (лише Debug-збірка): підміняє сервер заглушкою і перезавантажує.
    var scenario: LeaderboardScenario = .live {
        didSet {
            guard scenario != oldValue else { return }
            loadTask?.cancel()
            loadTask = Task { await load() }
        }
    }

    @ObservationIgnored private let provider: any LeaderboardProviding
    @ObservationIgnored let profile: PlayerProfile
    @ObservationIgnored let reporter: LeaderboardScoreReporter?
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    init(provider: any LeaderboardProviding,
         profile: PlayerProfile = PlayerProfile(),
         reporter: LeaderboardScoreReporter? = nil) {
        self.provider = provider
        self.profile = profile
        self.reporter = reporter
        nicknameDraft = profile.nickname
    }

    private var activeProvider: any LeaderboardProviding {
        scenario == .live ? provider : StubLeaderboard(scenario: scenario)
    }

    // MARK: - Завантаження

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    /// «Потягни, щоб оновити»: наявна таблиця лишається на екрані, поки йде запит.
    func refresh() async {
        await load(keepingData: true)
    }

    /// Завантажує топ. Поки йде запит, решта інтерфейсу доступна: стан лише показує індикатор.
    func load(keepingData: Bool = false) async {
        let previous = state
        if !(keepingData && previous.value != nil) {
            state = .loading
        }
        do {
            let entries = try await activeProvider.topScores(limit: Self.limit)
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch is CancellationError {
            state = previous == .loading ? .idle : previous
        } catch let error as URLError where error.code == .cancelled {
            state = previous == .loading ? .idle : previous
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    func retry() {
        loadTask?.cancel()
        loadTask = Task { await load() }
    }

    // MARK: - Рядки таблиці

    /// Свій запис: щойно надісланий або з поточним ніком.
    func isOwn(_ entry: LeaderboardEntry) -> Bool {
        entry.id == reporter?.lastResult?.entry.id || entry.player == profile.nickname
    }

    static func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    static func themeEmoji(_ rawValue: String) -> String {
        WorldTheme(rawValue: rawValue)?.emoji ?? "🎮"
    }

    // MARK: - Останній надісланий рахунок

    /// Текст про останнє надсилання; nil — у цьому запуску ще не грали нескінченний режим.
    var lastSubmissionText: String? {
        switch reporter?.status {
        case .sending(let score):
            return "Надсилаємо рахунок \(score)…"
        case .sent(let result):
            return "Твій рахунок \(result.entry.score) — \(result.rank) місце"
        case .failed(let score, let error):
            let reason = error.map { Self.message(for: $0) } ?? "невідома помилка"
            return "Рахунок \(score) не надіслано. \(reason)"
        case .idle, nil:
            return nil
        }
    }

    var lastSubmissionFailed: Bool {
        if case .failed = reporter?.status { return true }
        return false
    }

    // MARK: - Нік

    var canSaveNickname: Bool {
        PlayerProfile.normalized(nicknameDraft) != nil && PlayerProfile.normalized(nicknameDraft) != profile.nickname
    }

    func saveNickname() {
        nicknameMessage = PlayerProfile.validationMessage(for: nicknameDraft)
        guard nicknameMessage == nil, profile.update(nickname: nicknameDraft) else { return }
        nicknameDraft = profile.nickname
    }

    // MARK: - Тексти помилок

    /// Повідомлення для користувача.
    /// Після злиття частини A загальні тексти беруться з `NetworkError.userMessage`,
    /// тут лишиться тільки підказка про запуск власного сервера.
    static func message(for error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "Щось пішло не так. Спробуй ще раз."
        }
        switch networkError {
        case .transport(let code):
            switch code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "Немає інтернету. Перевір з'єднання і спробуй ще раз."
            case .timedOut:
                return "Сервер таблиці лідерів довго не відповідає. Спробуй ще раз."
            case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return "Сервер таблиці лідерів недоступний. Перевір, що він запущений (node server/index.js)."
            default:
                return "Не вдалося з'єднатися з сервером таблиці лідерів."
            }
        case .httpStatus(let status):
            return "Помилка сервера (код \(status)). Спробуй пізніше."
        case .decoding, .invalidResponse:
            return "Сервер надіслав неочікувану відповідь."
        }
    }
}
