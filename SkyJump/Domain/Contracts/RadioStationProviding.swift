import Foundation

/// Джерело списку радіостанцій (мережа, кеш або заглушка).
protocol RadioStationProviding {
    func stations(for genres: [RadioGenre]) async throws -> [RadioStation]
}

enum RadioError: Error, Equatable {
    case badResponse          // сервер відповів помилкою
    case noStations           // станцій, які можна відтворити, не знайдено
}
