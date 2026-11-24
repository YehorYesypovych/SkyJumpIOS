import Foundation
import Observation

/// ViewModel екрана «Лідери». Каркас: лише залежності; логіка — частина B.
@Observable
final class LeaderboardViewModel {
    private(set) var state: LoadState<[LeaderboardEntry]> = .idle

    @ObservationIgnored private let provider: any LeaderboardProviding

    init(provider: any LeaderboardProviding) {
        self.provider = provider
    }
}
