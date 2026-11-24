import Foundation

/// Джерело списку радіостанцій (мережа або заглушка).
/// Порожній масив — нормальна відповідь («нічого не знайдено»), помилки — `NetworkError`.
protocol RadioStationProviding {
    func stations(for genres: [RadioGenre]) async throws -> [RadioStation]
}
