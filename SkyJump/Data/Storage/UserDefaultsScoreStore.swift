import Foundation

/// Adapter: пристосовує системне `UserDefaults` до інтерфейсу `ScoreStoring`.
///
/// - Target — `ScoreStoring` (те, що потрібно ViewModel: `bestScore`, `submit(score:)`).
/// - Adaptee — `UserDefaults` (свій інтерфейс: `integer(forKey:)`, `set(_:forKey:)`, ключі-рядки).
/// - Adapter — цей клас; ViewModel не знає ні про `UserDefaults`, ні про ключ.
///
/// `UserDefaults` передається ззовні, тому в тестах можна підставити окремий suite.
final class UserDefaultsScoreStore: ScoreStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String = "bestScore") {
        self.defaults = defaults
        self.key = key
    }

    var bestScore: Int {
        defaults.integer(forKey: key)   // якщо значення ще немає — 0
    }

    @discardableResult
    func submit(score: Int) -> Bool {
        guard score > bestScore else { return false }
        defaults.set(score, forKey: key)
        return true
    }
}
