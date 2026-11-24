import Foundation

/// Клієнт відкритого каталогу інтернет-радіо Radio Browser (radio-browser.info): без ключа,
/// станції шукаються за тегом-жанром. Якщо один сервер недоступний, пробується наступний.
struct RadioBrowserClient: RadioStationProviding {
    static let servers = ["de1.api.radio-browser.info",
                          "de2.api.radio-browser.info",
                          "fi1.api.radio-browser.info"]

    private let session: URLSession
    private let mapper: RadioStationMapper
    private let limitPerGenre: Int

    init(session: URLSession = .shared, mapper: RadioStationMapper = RadioStationMapper(), limitPerGenre: Int = 25) {
        self.session = session
        self.mapper = mapper
        self.limitPerGenre = limitPerGenre
    }

    func stations(for genres: [RadioGenre]) async throws -> [RadioStation] {
        var collected: [RadioBrowserStationDTO] = []
        var lastError: Error?

        // жанр, що не завантажився, не ламає весь список — помилка лише якщо не вдалося нічого
        for genre in genres {
            do {
                collected += try await fetch(tag: genre.rawValue)
            } catch {
                lastError = error
            }
        }
        if collected.isEmpty, let lastError {
            throw lastError
        }

        let stations = mapper.map(collected)
        guard !stations.isEmpty else { throw RadioError.noStations }
        return stations
    }

    /// Запит станцій одного тегу з перебором серверів.
    private func fetch(tag: String) async throws -> [RadioBrowserStationDTO] {
        var lastError: Error = RadioError.badResponse
        for host in Self.servers {
            do {
                let request = makeRequest(host: host, tag: tag)
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw RadioError.badResponse
                }
                return try JSONDecoder().decode([RadioBrowserStationDTO].self, from: data)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    func makeRequest(host: String, tag: String) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/json/stations/bytag/\(tag)"
        components.queryItems = [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "clickcount"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "limit", value: "\(limitPerGenre)")
        ]
        var request = URLRequest(url: components.url ?? URL(string: "https://\(host)")!, timeoutInterval: 10)
        // каталог просить представлятися назвою застосунку
        request.setValue("SkyJump/1.0", forHTTPHeaderField: "User-Agent")
        return request
    }
}

/// Станція у форматі відповіді Radio Browser (лише потрібні поля).
struct RadioBrowserStationDTO: Decodable {
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
