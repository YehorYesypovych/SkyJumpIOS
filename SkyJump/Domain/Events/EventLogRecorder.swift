import Foundation

/// Спостерігач, що збирає рядки журналу для показу на екрані.
final class EventLogRecorder: GameEventObserver {
    private(set) var lines: [String] = []

    func gameSession(didEmit event: GameEvent, at time: Double) {
        lines.append(event.logLine(at: time))
    }
}
