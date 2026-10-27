import Foundation

/// Подія, що сталася під час ігрової сесії.
enum GameEvent {
    case started(playerName: String, platformCount: Int)
    case jumped(platformID: Int, type: PlatformType, height: Double)
    case platformBroken(platformID: Int)
    case platformsRemoved(count: Int)
    case playerFell
    case finished
}

/// Observer: отримує події від GameSession (Subject).
/// Сесія не знає, що саме спостерігач робить з подією — пише журнал, друкує в консоль тощо.
protocol GameEventObserver: AnyObject {
    func gameSession(didEmit event: GameEvent, at time: Double)
}

extension GameEvent {
    /// Текст події для журналу.
    var message: String {
        switch self {
        case let .started(playerName, platformCount):
            return "Старт: \(playerName), платформ на рівні: \(platformCount)"
        case let .jumped(platformID, type, height):
            return "Стрибок з платформи #\(platformID) (\(type.title)) на висоті \(Int(height))"
        case let .platformBroken(platformID):
            return "Платформа #\(platformID) зламалась, гравець падає далі"
        case let .platformsRemoved(count):
            return "Прибрано платформ нижче екрана: \(count)"
        case .playerFell:
            return "Гравець впав. Гру закінчено"
        case .finished:
            return "Симуляцію завершено"
        }
    }

    /// Рядок журналу з часом події: "[ 0.02 с] …".
    func logLine(at time: Double) -> String {
        "[\(String(format: "%5.2f", time)) с] \(message)"
    }
}
