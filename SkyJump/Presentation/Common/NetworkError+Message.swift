import Foundation

/// Тексти помилок для користувача: окремо «немає інтернету», «таймаут», «сервер недоступний»,
/// «помилка сервера» і «неочікувана відповідь». Технічні подробиці (код, поле JSON) — лише в логах.
extension NetworkError {
    var userMessage: String {
        switch self {
        case .transport(let code):
            switch code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                return "Немає інтернету. Перевір з'єднання і спробуй ще раз."
            case .timedOut:
                return "Сервер довго не відповідає. Спробуй ще раз."
            case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return "Сервер недоступний. Спробуй трохи згодом."
            default:
                return "Не вдалося зв'язатися із сервером. Спробуй ще раз."
            }
        case .httpStatus(let code) where code >= 500:
            return "Помилка на сервері (код \(code)). Спробуй трохи згодом."
        case .httpStatus(let code):
            return "Сервер відхилив запит (код \(code))."
        case .decoding, .invalidResponse:
            return "Сервер надіслав неочікувану відповідь. Спробуй трохи згодом."
        }
    }

    /// Текст для будь-якої помилки: `URLError` трактується як транспортна.
    static func userMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userMessage
        }
        if let urlError = error as? URLError {
            return NetworkError.transport(urlError.code).userMessage
        }
        return "Щось пішло не так. Спробуй ще раз."
    }
}
