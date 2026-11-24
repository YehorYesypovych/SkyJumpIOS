import Foundation

/// Стан відтворення потоку.
enum StreamState: Equatable {
    case idle
    case loading
    case playing
    case failed
}

/// Програвач аудіопотоку. Реалізація на AVPlayer — у Data, у тестах — шпигун.
protocol AudioStreaming: AnyObject {
    var onStateChange: ((StreamState) -> Void)? { get set }
    var volume: Float { get set }
    func play(url: URL)
    func stop()
}
