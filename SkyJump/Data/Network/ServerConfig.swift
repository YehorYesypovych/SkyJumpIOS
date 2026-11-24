import Foundation

/// Адреса власного сервера таблиці лідерів.
///
/// За замовчуванням — сервер на тому ж Mac, де запущено симулятор. Для iPhone адресу задають
/// аргументом запуску `-serverURL http://<IP Mac>:8080` (Edit Scheme → Run → Arguments):
/// аргументи виду `-ключ значення` iOS кладе в `UserDefaults`.
enum ServerConfig {
    static let defaultURL = URL(string: "http://localhost:8080")!

    static func baseURL(defaults: UserDefaults = .standard) -> URL {
        defaults.string(forKey: "serverURL").flatMap(URL.init(string:)) ?? defaultURL
    }
}
