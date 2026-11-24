import Foundation
import Observation

/// ViewModel екрана «Радіо»: завантажує станції з каталогу, фільтрує за жанром, керує відтворенням.
///
/// Стан екрана — `LoadState`: завантаження → дані / порожньо / помилка з повтором.
@Observable
final class RadioViewModel {
    private(set) var state: LoadState<[RadioStation]> = .idle
    var selectedGenre: RadioGenre?          // nil — усі жанри

    @ObservationIgnored let player: RadioPlayer
    @ObservationIgnored private let provider: any RadioStationProviding

    init(provider: any RadioStationProviding, player: RadioPlayer) {
        self.provider = provider
        self.player = player
        // станції вже завантажували раніше — показуємо одразу, без мережі
        if !player.queue.isEmpty {
            state = .loaded(player.queue)
        }
    }

    /// Завантажені станції (порожньо, поки даних немає).
    var stations: [RadioStation] {
        state.value ?? []
    }

    var visibleStations: [RadioStation] {
        guard let selectedGenre else { return stations }
        return stations.filter { $0.tags.contains(selectedGenre.rawValue) }
    }

    /// Завантажує станції, якщо їх ще немає.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Завантажує станції з каталогу (кнопка «Спробувати ще раз» і «потягни, щоб оновити»).
    func load() async {
        guard !state.isLoading else { return }
        // при оновленні вже показаного списку він лишається на екрані, поки йде запит
        if state.value == nil {
            state = .loading
        }
        do {
            let result = try await provider.stations(for: RadioGenre.allCases)
            if result.isEmpty {
                state = .empty
            } else {
                player.setQueue(result)
                state = .loaded(result)
            }
        } catch is CancellationError {
            // екран закрили під час запиту — стан не змінюємо
            if state.isLoading { state = .idle }
        } catch {
            state = .failed(message: NetworkError.userMessage(for: error))
        }
    }

    func isCurrent(_ station: RadioStation) -> Bool {
        player.current?.id == station.id
    }

    /// Тап по станції: увімкнути її або вимкнути, якщо вона вже грає.
    func select(_ station: RadioStation) {
        if isCurrent(station) && player.isActive {
            player.stop()
        } else {
            player.play(station)
        }
    }
}
