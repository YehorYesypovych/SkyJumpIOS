import Foundation

/// Клієнт відкритого каталогу інтернет-радіо Radio Browser (radio-browser.info): без ключа,
/// станції шукаються за тегом-жанром.
///
/// З мережею напряму не працює — отримує мережевий компонент `HTTPClient` для кожного
/// дзеркала каталогу. Якщо дзеркало недоступне (помилка мережі або `5xx`), пробується наступне.
/// Помилка формату чи `4xx` не лікується іншим сервером, тому віддається одразу.
struct RadioBrowserClient: RadioStationProviding {
    static let servers = ["de1.api.radio-browser.info",
                          "de2.api.radio-browser.info",
                          "fi1.api.radio-browser.info"]

    /// Справжні клієнти — по одному на дзеркало.
    static func liveClients() -> [any HTTPClient] {
        servers.compactMap { URL(string: "https://\($0)") }
            .map { URLSessionHTTPClient(baseURL: $0, timeout: 10) }
    }

    private let clients: [any HTTPClient]
    private let mapper: RadioStationMapper
    private let limitPerGenre: Int

    init(clients: [any HTTPClient], mapper: RadioStationMapper = RadioStationMapper(), limitPerGenre: Int = 25) {
        self.clients = clients
        self.mapper = mapper
        self.limitPerGenre = limitPerGenre
    }

    /// Станції всіх жанрів. Порожній масив — не помилка: екран покаже стан «порожньо».
    func stations(for genres: [RadioGenre]) async throws -> [RadioStation] {
        var collected: [RadioBrowserStationDTO] = []
        var failures = 0
        var lastError: Error?

        // жанр, що не завантажився, не ламає весь список — помилка лише якщо не вдався жоден запит
        for genre in genres {
            do {
                collected += try await fetch(tag: genre.rawValue)
            } catch {
                failures += 1
                lastError = error
            }
        }
        if failures == genres.count, let lastError {
            throw lastError
        }
        return mapper.map(collected)
    }

    /// Запит станцій одного тегу з перебором дзеркал.
    private func fetch(tag: String) async throws -> [RadioBrowserStationDTO] {
        var lastError: Error = NetworkError.invalidResponse
        for client in clients {
            do {
                return try await client.send(request(tag: tag), as: [RadioBrowserStationDTO].self)
            } catch let error as NetworkError where Self.shouldTryNextServer(after: error) {
                lastError = error
            }
        }
        throw lastError
    }

    /// Чи є сенс питати інше дзеркало після такої помилки.
    static func shouldTryNextServer(after error: NetworkError) -> Bool {
        switch error {
        case .transport, .invalidResponse:
            return true
        case .httpStatus(let code):
            return code >= 500
        case .decoding:
            return false
        }
    }

    /// `GET /json/stations/bytag/{tag}` — найпопулярніші робочі станції жанру.
    func request(tag: String) -> HTTPRequest {
        HTTPRequest(path: "/json/stations/bytag/\(tag)",
                    query: [
                        URLQueryItem(name: "hidebroken", value: "true"),
                        URLQueryItem(name: "order", value: "clickcount"),
                        URLQueryItem(name: "reverse", value: "true"),
                        URLQueryItem(name: "limit", value: "\(limitPerGenre)")
                    ])
    }
}

/// Станція у форматі відповіді Radio Browser (лише потрібні поля).
/// `nonisolated`: декодування не прив'язане до головного потоку, тому модель можна віддати в `HTTPClient.send`.
nonisolated struct RadioBrowserStationDTO: Decodable, Sendable {
    let stationuuid: String
    let name: String
    let url: String
    let urlResolved: String?
    let country: String?
    let countrycode: String?
    let tags: String?
    let favicon: String?
    let codec: String?
    let bitrate: Int?
    let lastcheckok: Int?
    let clickcount: Int?

    enum CodingKeys: String, CodingKey {
        case stationuuid, name, url, country, countrycode, tags, favicon, codec, bitrate, lastcheckok, clickcount
        case urlResolved = "url_resolved"
    }
}

/// Перетворює відповідь каталогу на станції, які застосунок справді може відтворити.
struct RadioStationMapper {
    /// Формати, які відтворює AVPlayer.
    static let supportedCodecs: Set<String> = ["MP3", "AAC", "AAC+", "HLS"]

    func map(_ items: [RadioBrowserStationDTO]) -> [RadioStation] {
        var seenNames = Set<String>()

        return items
            .sorted { ($0.clickcount ?? 0) > ($1.clickcount ?? 0) }
            .compactMap { item -> RadioStation? in
                // остання перевірка каталогу не пройшла — станція, ймовірно, не працює
                guard (item.lastcheckok ?? 1) == 1 else { return nil }

                // лише https: iOS за замовчуванням не пускає незахищені потоки
                let rawURL = (item.urlResolved?.isEmpty == false ? item.urlResolved : nil) ?? item.url
                guard let streamURL = URL(string: rawURL), streamURL.scheme?.lowercased() == "https" else { return nil }

                if let codec = item.codec?.uppercased(), !codec.isEmpty, !Self.supportedCodecs.contains(codec) {
                    return nil
                }

                let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                // одна станція часто повторюється в кількох жанрах
                guard !name.isEmpty, seenNames.insert(name.lowercased()).inserted else { return nil }

                let tags = (item.tags ?? "")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                    .filter { !$0.isEmpty }
                let favicon = item.favicon
                    .flatMap { URL(string: $0) }
                    .flatMap { $0.scheme?.lowercased() == "https" ? $0 : nil }

                return RadioStation(id: item.stationuuid,
                                    name: name,
                                    streamURL: streamURL,
                                    country: item.country ?? "",
                                    countryCode: (item.countrycode ?? "").uppercased(),
                                    tags: tags,
                                    faviconURL: favicon,
                                    bitrate: item.bitrate ?? 0)
            }
    }
}
