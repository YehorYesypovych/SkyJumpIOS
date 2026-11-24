import Foundation
import Observation

/// Надсилає рахунок нескінченного режиму в таблицю лідерів з ніком гравця і обраною темою.
///
/// Гра викликає `report(score:)` і одразу продовжує роботу: запит іде в окремому `Task`.
/// Останній результат (місце в таблиці або помилка) зберігається для показу на екрані «Лідери».
@Observable
final class LeaderboardScoreReporter: ScoreReporting {
    enum Status: Equatable {
        case idle
        case sending(score: Int)
        case sent(SubmitResult)
        case failed(score: Int, error: NetworkError?)
    }

    private(set) var status: Status = .idle

    @ObservationIgnored private let provider: any LeaderboardProviding
    @ObservationIgnored private let profile: PlayerProfile
    @ObservationIgnored private let cosmetics: CosmeticsSettings
    /// Поточне надсилання — у тестах його можна дочекатися.
    @ObservationIgnored private(set) var pendingTask: Task<Void, Never>?

    init(provider: any LeaderboardProviding, profile: PlayerProfile, cosmetics: CosmeticsSettings) {
        self.provider = provider
        self.profile = profile
        self.cosmetics = cosmetics
    }

    /// Останній успішно надісланий результат.
    var lastResult: SubmitResult? {
        if case .sent(let result) = status { return result }
        return nil
    }

    func report(score: Int) {
        // гра, що закінчилась без жодного стрибка, у таблицю не потрапляє
        guard score > 0 else { return }

        let submission = ScoreSubmission(player: profile.nickname,
                                         score: score,
                                         theme: cosmetics.theme.rawValue)
        status = .sending(score: score)
        pendingTask = Task { [weak self, provider] in
            do {
                let result = try await provider.submit(submission)
                self?.status = .sent(result)
            } catch is CancellationError {
                self?.status = .idle
            } catch {
                self?.status = .failed(score: score, error: error as? NetworkError)
            }
        }
    }
}
