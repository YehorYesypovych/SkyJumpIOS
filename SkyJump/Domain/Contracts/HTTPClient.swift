import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

/// Опис запиту без прив'язки до сервера: шлях відносно базової адреси клієнта.
struct HTTPRequest {
    var method: HTTPMethod = .get
    var path: String
    var query: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
}

/// Три різні види відмов + некоректна відповідь.
enum NetworkError: Error, Equatable {
    /// Запит не дійшов або відповідь не прийшла: немає мережі, таймаут, хост недоступний.
    case transport(URLError.Code)
    /// Сервер відповів, але статусом 4xx/5xx.
    case httpStatus(Int)
    /// Відповідь прийшла, але не відповідає очікуваній моделі.
    case decoding(String)
    /// Не HTTP-відповідь або не вдалося скласти адресу.
    case invalidResponse
}

/// Мережевий компонент застосунку: єдине місце, звідки йдуть HTTP-запити.
protocol HTTPClient {
    /// Надсилає запит, перевіряє HTTP-статус і лише потім декодує JSON у T.
    func send<T: Decodable>(_ request: HTTPRequest, as type: T.Type) async throws -> T
}
