import Foundation
import Testing
@testable import SkyJump

/// Підміняє мережу для URLSession: відповідь задає тест, справжніх запитів немає.
/// Обробники прив'язані до хоста, тому тести можуть іти паралельно.
final class StubURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (status: Int, body: Data)

    private nonisolated(unsafe) static var handlers: [String: Handler] = [:]
    private nonisolated(unsafe) static var captured: [String: URLRequest] = [:]
    private static let lock = NSLock()

    /// Сесія, що ходить лише в заглушку, і базова адреса з унікальним хостом.
    static func register(_ handler: @escaping Handler) -> (session: URLSession, baseURL: URL) {
        let host = "test-\(UUID().uuidString.lowercased()).example"
        lock.withLock { handlers[host] = handler }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return (URLSession(configuration: configuration), URL(string: "https://\(host)/api")!)
    }

    /// Запит, який дійшов до «мережі».
    static func lastRequest(for baseURL: URL) -> URLRequest? {
        lock.withLock { captured[baseURL.host ?? ""] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let host = request.url?.host ?? ""
        let handler = Self.lock.withLock { () -> Handler? in
            Self.captured[host] = request
            return Self.handlers[host]
        }
        do {
            guard let handler else { throw URLError(.cannotFindHost) }
            let (status, body) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Модель для перевірки декодування.
private struct Echo: Decodable, Equatable, Sendable {
    let name: String
    let count: Int
}

@MainActor
struct URLSessionHTTPClientTests {

    private func makeClient(_ handler: @escaping StubURLProtocol.Handler) -> (URLSessionHTTPClient, URL) {
        let (session, baseURL) = StubURLProtocol.register(handler)
        return (URLSessionHTTPClient(baseURL: baseURL, session: session), baseURL)
    }

    @Test func validJSONIsDecoded() async throws {
        let (client, _) = makeClient { _ in (200, Data(#"{"name": "neon", "count": 3}"#.utf8)) }

        let echo = try await client.send(HTTPRequest(path: "/echo"), as: Echo.self)

        #expect(echo == Echo(name: "neon", count: 3))
    }

    @Test func serverErrorIsReportedBeforeDecoding() async {
        // тіло — HTML, але до декодування справа не доходить: спершу перевіряється статус
        let (client, _) = makeClient { _ in (500, Data("<html>Internal Server Error</html>".utf8)) }

        await #expect(throws: NetworkError.httpStatus(500)) {
            try await client.send(HTTPRequest(path: "/echo"), as: Echo.self)
        }
    }

    @Test func clientErrorStatusIsReported() async {
        // навіть коректний JSON із кодом 404 не вважається успіхом
        let (client, _) = makeClient { _ in (404, Data(#"{"name": "x", "count": 1}"#.utf8)) }

        await #expect(throws: NetworkError.httpStatus(404)) {
            try await client.send(HTTPRequest(path: "/missing"), as: Echo.self)
        }
    }

    @Test func invalidJSONIsDecodingError() async {
        let (client, _) = makeClient { _ in (200, Data(#"{"name": 42}"#.utf8)) }

        do {
            _ = try await client.send(HTTPRequest(path: "/echo"), as: Echo.self)
            Issue.record("Очікувалася помилка декодування")
        } catch let error as NetworkError {
            guard case .decoding(let details) = error else {
                Issue.record("Очікувалася .decoding, а прийшла \(error)")
                return
            }
            #expect(!details.isEmpty)
        } catch {
            Issue.record("Неочікувана помилка \(error)")
        }
    }

    @Test func noInternetIsTransportError() async {
        let (client, _) = makeClient { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: NetworkError.transport(.notConnectedToInternet)) {
            try await client.send(HTTPRequest(path: "/echo"), as: Echo.self)
        }
    }

    @Test func requestReachesNetworkWithPathQueryAndHeaders() async throws {
        let (client, baseURL) = makeClient { _ in (200, Data(#"{"name": "ok", "count": 0}"#.utf8)) }

        _ = try await client.send(HTTPRequest(path: "/leaderboard",
                                              query: [URLQueryItem(name: "limit", value: "20")],
                                              headers: ["X-Check": "1"]),
                                  as: Echo.self)

        let sent = try #require(StubURLProtocol.lastRequest(for: baseURL))
        #expect(sent.url?.path == "/api/leaderboard")          // шлях дописується до базового
        #expect(sent.url?.query == "limit=20")
        #expect(sent.httpMethod == "GET")
        #expect(sent.value(forHTTPHeaderField: "User-Agent") == "SkyJump/1.0")
        #expect(sent.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(sent.value(forHTTPHeaderField: "X-Check") == "1")
    }

    @Test func postRequestCarriesBody() throws {
        let client = URLSessionHTTPClient(baseURL: URL(string: "http://localhost:8080")!)
        let body = Data(#"{"score": 10}"#.utf8)

        let request = try #require(client.makeURLRequest(HTTPRequest(method: .post, path: "api/scores",
                                                                     headers: ["Content-Type": "application/json"],
                                                                     body: body)))

        #expect(request.url?.absoluteString == "http://localhost:8080/api/scores")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == body)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
}

@MainActor
struct NetworkErrorMessageTests {

    @Test func differentFailuresHaveDifferentTexts() {
        let messages = [
            NetworkError.transport(.notConnectedToInternet).userMessage,
            NetworkError.transport(.timedOut).userMessage,
            NetworkError.transport(.cannotConnectToHost).userMessage,
            NetworkError.httpStatus(500).userMessage,
            NetworkError.httpStatus(404).userMessage,
            NetworkError.decoding("немає поля").userMessage
        ]

        #expect(Set(messages).count == messages.count)
        #expect(messages[0].contains("інтернету"))
        #expect(messages[3].contains("500"))
    }

    @Test func technicalDetailsAreNotShown() {
        #expect(!NetworkError.decoding("немає поля «name»").userMessage.contains("name"))
    }

    @Test func urlErrorIsTreatedAsTransport() {
        #expect(NetworkError.userMessage(for: URLError(.timedOut)) == NetworkError.transport(.timedOut).userMessage)
    }
}
