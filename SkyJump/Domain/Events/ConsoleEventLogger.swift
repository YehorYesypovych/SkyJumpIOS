import Foundation

/// Спостерігач, що виводить події в консоль.
/// Куди саме писати, передається ззовні — за замовчуванням print (консоль Xcode).
final class ConsoleEventLogger: GameEventObserver {
    private let output: (String) -> Void

    init(output: @escaping (String) -> Void = { print($0) }) {
        self.output = output
    }

    func gameSession(didEmit event: GameEvent, at time: Double) {
        output(event.logLine(at: time))
    }
}
