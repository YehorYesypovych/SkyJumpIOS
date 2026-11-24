import Foundation
import Observation

/// ViewModel екрана «Радіо»: завантажує станції з каталогу, фільтрує за жанром, керує відтворенням.
@Observable
final class RadioViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var stations: [RadioStation] = []
    var selectedGenre: RadioGenre?          // nil — усі жанри

    @ObservationIgnored let player: RadioPlayer
    @ObservationIgnored private let provider: any RadioStationProviding

    init(provider: any RadioStationProviding, player: RadioPlayer) {
        self.provider = provider
        self.player = player
        // станції вже завантажували раніше — показуємо одразу, без мережі
        if !player.queue.isEmpty {
            stations = player.queue
            loadState = .loaded
        }
    }

    var visibleStations: [RadioStation] {
        guard let selectedGenre else { return stations }
        return stations.filter { $0.tags.contains(selectedGenre.rawValue) }
    }

    /// Завантажує станції, якщо їх ще немає.
    func loadIfNeeded() async {
        guard stations.isEmpty else { return }
        await load()
    }

    /// Завантажує станції з каталогу (також для «потягни, щоб оновити»).
    func load() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let result = try await provider.stations(for: RadioGenre.allCases)
            stations = result
            player.setQueue(result)
            loadState = .loaded
        } catch {
            loadState = .failed(Self.message(for: error))
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

    static func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "Немає інтернету. Перевір з'єднання і спробуй ще раз."
            case .timedOut:
                return "Сервер радіо довго не відповідає. Спробуй ще раз."
            default:
                break
            }
        }
        if let radioError = error as? RadioError, radioError == .noStations {
            return "Не знайшли станцій, які можна відтворити."
        }
        return "Каталог радіо зараз недоступний. Спробуй трохи згодом."
    }
}
