import Foundation

/// Реалізація мережевого компонента на URLSession.
///
/// Порядок обробки відповіді:
/// 1. запит не відбувся (`URLError`) → `NetworkError.transport`;
/// 2. відповідь не HTTP → `.invalidResponse`;
/// 3. статус не 2xx → `.httpStatus` — тіло як успішні дані не розбирається;
/// 4. JSON не відповідає моделі (`DecodingError`) → `.decoding`.
final class URLSessionHTTPClient: HTTPClient {
    let baseURL: URL
    private let session: URLSession
    private let defaultHeaders: [String: String]
    private let decoder: JSONDecoder
    private let timeout: TimeInterval

    init(baseURL: URL,
         session: URLSession = .shared,
         defaultHeaders: [String: String] = ["User-Agent": "SkyJump/1.0", "Accept": "application/json"],
         decoder: JSONDecoder = .skyJump,
         timeout: TimeInterval = 15) {
        self.baseURL = baseURL
        self.session = session
        self.defaultHeaders = defaultHeaders
        self.decoder = decoder
        self.timeout = timeout
    }

    func send<T: Decodable & Sendable>(_ request: HTTPRequest, as type: T.Type) async throws -> T {
        let data = try await data(for: request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(Self.describe(error))
        }
    }

    /// Тіло успішної відповіді (статус 2xx).
    func data(for request: HTTPRequest) async throws -> Data {
        guard let urlRequest = makeURLRequest(request) else {
            throw NetworkError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError where error.code != .cancelled {
            throw NetworkError.transport(error.code)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }
        return data
    }

    /// Збирає URLRequest: базова адреса + шлях + параметри + заголовки + тіло.
    func makeURLRequest(_ request: HTTPRequest) -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + (request.path.hasPrefix("/") ? request.path : "/" + request.path)
        components.queryItems = request.query.isEmpty ? nil : request.query
        guard let url = components.url else { return nil }

        var urlRequest = URLRequest(url: url, timeoutInterval: timeout)
        urlRequest.httpMethod = request.method.rawValue
        for (field, value) in defaultHeaders.merging(request.headers, uniquingKeysWith: { _, new in new }) {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        urlRequest.httpBody = request.body
        return urlRequest
    }

    /// Короткий опис помилки декодування: якого поля не вистачило чи який тип не збігся.
    static func describe(_ error: DecodingError) -> String {
        func path(_ context: DecodingError.Context) -> String {
            context.codingPath.map(\.stringValue).joined(separator: ".")
        }
        switch error {
        case .keyNotFound(let key, let context):
            return "немає поля «\(key.stringValue)» \(path(context))"
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            return "неправильний тип у «\(path(context))»"
        case .dataCorrupted(let context):
            return "пошкоджені дані \(path(context))"
        @unknown default:
            return "невідома помилка формату"
        }
    }
}

extension JSONDecoder {
    /// Декодер застосунку: дати у форматі ISO 8601.
    static var skyJump: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    /// Кодувальник застосунку: дати у форматі ISO 8601.
    static var skyJump: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
