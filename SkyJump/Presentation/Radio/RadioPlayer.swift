import Foundation
import Observation

/// Радіо застосунку — одне на весь застосунок, як у машині в GTA: грає в меню й під час гри.
/// Пам'ятає останню станцію, перемикає наступну зі списку, притишується на паузі гри.
@Observable
final class RadioPlayer {
    private(set) var current: RadioStation?
    private(set) var state: StreamState = .idle
    private(set) var queue: [RadioStation] = []
    private(set) var isDucked = false

    static let normalVolume: Float = 1
    static let duckedVolume: Float = 0.25

    @ObservationIgnored private let streamer: AudioStreaming
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    init(streamer: AudioStreaming, defaults: UserDefaults = .standard, key: String = "radio.lastStation") {
        self.streamer = streamer
        self.defaults = defaults
        self.key = key
        self.current = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(RadioStation.self, from: $0) }
        streamer.onStateChange = { [weak self] state in
            self?.state = state
        }
    }

    /// Грає або підключається.
    var isActive: Bool { state == .playing || state == .loading }

    func setQueue(_ stations: [RadioStation]) {
        queue = stations
    }

    func play(_ station: RadioStation) {
        current = station
        if let data = try? JSONEncoder().encode(station) {
            defaults.set(data, forKey: key)
        }
        streamer.volume = isDucked ? Self.duckedVolume : Self.normalVolume
        streamer.play(url: station.streamURL)
    }

    func stop() {
        streamer.stop()
        state = .idle
    }

    /// Пуск/стоп поточної станції.
    func toggle() {
        if isActive {
            stop()
        } else if let current {
            play(current)
        }
    }

    /// Наступна станція зі списку (по колу).
    func playNext() {
        guard !queue.isEmpty else { return }
        let currentIndex = current.flatMap { station in queue.firstIndex { $0.id == station.id } }
        let nextIndex = currentIndex.map { ($0 + 1) % queue.count } ?? 0
        play(queue[nextIndex])
    }

    /// Притишити (пауза гри) або повернути гучність.
    func setDucked(_ ducked: Bool) {
        guard ducked != isDucked else { return }
        isDucked = ducked
        streamer.volume = ducked ? Self.duckedVolume : Self.normalVolume
    }
}
