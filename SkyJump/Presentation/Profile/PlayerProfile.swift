import Foundation
import Observation

/// Профіль гравця: нік, під яким рахунок потрапляє в таблицю лідерів. Зберігається в UserDefaults.
@Observable
final class PlayerProfile {
    static let defaultNickname = "Doodler"
    static let nicknameLengthRange = 1...20

    private(set) var nickname: String

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "profile.nickname"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        nickname = defaults.string(forKey: Self.key).flatMap(Self.normalized) ?? Self.defaultNickname
    }

    /// Змінює нік, якщо він правильний. Повертає false — нік не змінено.
    @discardableResult
    func update(nickname newValue: String) -> Bool {
        guard let valid = Self.normalized(newValue) else { return false }
        nickname = valid
        defaults.set(valid, forKey: Self.key)
        return true
    }

    /// Нік без пробілів по краях; nil — порожній або задовгий.
    static func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return nicknameLengthRange.contains(trimmed.count) ? trimmed : nil
    }

    /// Пояснення, чому нік не підходить; nil — підходить.
    static func validationMessage(for value: String) -> String? {
        let length = value.trimmingCharacters(in: .whitespacesAndNewlines).count
        if length < nicknameLengthRange.lowerBound { return "Введи нік" }
        if length > nicknameLengthRange.upperBound { return "Нік — до \(nicknameLengthRange.upperBound) символів" }
        return nil
    }
}
