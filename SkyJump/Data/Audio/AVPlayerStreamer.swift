import AVFoundation
import Foundation

/// Відтворення інтернет-радіо через AVPlayer. Стан повідомляється через `onStateChange`.
final class AVPlayerStreamer: AudioStreaming {
    var onStateChange: ((StreamState) -> Void)?

    private let player = AVPlayer()
    private var statusObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?

    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }

    init() {
        #if canImport(UIKit)
        // налаштування аудіосесії може надовго заблокувати потік, тому — не на головному
        Task.detached(priority: .userInitiated) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        }
        #endif
        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            // weak self захоплюється заново: задача не звертається до змінної іншого замикання
            Task { @MainActor [weak self] in
                self?.report(status)
            }
        }
    }

    func play(url: URL) {
        // категорію сесії (звук і з вимкненим перемикачем) задано в init поза головним потоком;
        // активує сесію сам AVPlayer, коли починає грати
        let item = AVPlayerItem(url: url)
        itemObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor [weak self] in
                self?.onStateChange?(.failed)
            }
        }
        player.replaceCurrentItem(with: item)
        onStateChange?(.loading)
        player.play()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        itemObservation = nil
        onStateChange?(.idle)
    }

    private func report(_ status: AVPlayer.TimeControlStatus) {
        guard player.currentItem != nil else { return }
        switch status {
        case .playing:
            onStateChange?(.playing)
        case .waitingToPlayAtSpecifiedRate:
            onStateChange?(.loading)
        case .paused:
            break
        @unknown default:
            break
        }
    }
}
