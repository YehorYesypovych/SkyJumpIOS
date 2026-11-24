import Foundation

/// Результат приземлення на платформу.
enum LandingOutcome {
    case jumped(velocity: Double)   // гравець відштовхнувся з цією швидкістю
    case broke                      // платформа зламалась, гравець падає далі
}

/// Strategy: поведінка платформи, коли на неї приземляється гравець.
/// Context — GameSession: він знаходить платформу і делегує їй рішення,
/// не знаючи, який саме тип платформи перед ним.
protocol LandingStrategy {
    func land(player: Player, on platform: inout Platform) -> LandingOutcome
}

/// Відскок із заданою швидкістю: звичайна, рухома платформа, пружина.
struct BounceLanding: LandingStrategy {
    let velocity: Double

    func land(player: Player, on platform: inout Platform) -> LandingOutcome {
        player.jump(velocity: velocity)
        return .jumped(velocity: velocity)
    }
}

/// Ламка платформа: не відштовхує, а ламається під гравцем.
struct BreakLanding: LandingStrategy {
    func land(player: Player, on platform: inout Platform) -> LandingOutcome {
        platform.breakPlatform()
        return .broke
    }
}

/// Ламка платформа, що витримує один стрибок: перше приземлення — звичайний стрибок
/// і тріщина, друге — платформа розсипається, гравець падає далі.
struct CrumbleLanding: LandingStrategy {
    let velocity: Double

    func land(player: Player, on platform: inout Platform) -> LandingOutcome {
        guard platform.isCracked else {
            platform.crack()
            player.jump(velocity: velocity)
            return .jumped(velocity: velocity)
        }
        platform.breakPlatform()
        return .broke
    }
}

/// Набори стратегій для типів платформ.
enum LandingStrategies {
    /// Стандартний набір: звичайний стрибок і посилений стрибок з пружини за правилами rules.
    static func standard(rules: GameRules = .standard) -> [PlatformType: LandingStrategy] {
        let jump = BounceLanding(velocity: rules.jumpVelocity)
        return [
            .normal: jump,
            .moving: jump,
            .spring: BounceLanding(velocity: rules.jumpVelocity * rules.springMultiplier),
            .breakable: BreakLanding()
        ]
    }

    /// Набір для справжньої гри: ламка платформа витримує один стрибок.
    /// У симуляції лишається стандартний набір, тож демо-сценарій не змінюється.
    static func gameplay(rules: GameRules = .standard) -> [PlatformType: LandingStrategy] {
        var strategies = standard(rules: rules)
        strategies[.breakable] = CrumbleLanding(velocity: rules.jumpVelocity)
        return strategies
    }
}
