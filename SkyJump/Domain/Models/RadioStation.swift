import Foundation

/// Інтернет-радіостанція з каталогу.
struct RadioStation: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let streamURL: URL
    let country: String
    let countryCode: String
    let tags: [String]          // у нижньому регістрі
    let faviconURL: URL?
    let bitrate: Int

    /// Прапор країни з дволітерного коду (US → 🇺🇸); порожній, якщо коду немає.
    var flag: String {
        let letters = countryCode.uppercased().unicodeScalars
        guard letters.count == 2 else { return "" }
        return String(String.UnicodeScalarView(letters.compactMap { UnicodeScalar(127_397 + $0.value) }))
    }

    /// Перший жанр зі списку тегів — для короткого підпису.
    var genre: String { tags.first ?? "radio" }
}

/// Жанри, під які підбираються станції: звук неонового пляжу.
enum RadioGenre: String, CaseIterable, Identifiable {
    case synthwave
    case retrowave
    case vaporwave
    case eighties = "80s"
    case chillwave

    var id: Self { self }

    var title: String {
        switch self {
        case .synthwave: return "Synthwave"
        case .retrowave: return "Retrowave"
        case .vaporwave: return "Vaporwave"
        case .eighties: return "80s"
        case .chillwave: return "Chillwave"
        }
    }
}
