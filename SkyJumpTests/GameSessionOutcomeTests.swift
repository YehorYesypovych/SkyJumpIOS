import Testing
@testable import SkyJump

/// Режим справжньої гри: перемога на висоті верхньої платформи, поразка при падінні.
@MainActor
struct GameSessionOutcomeTests {

    /// Платформи одна над одною: гравець без керування піднімається до верху.
    private let tower = [
        Platform(id: 0, x: 160, y: 0),
        Platform(id: 1, x: 160, y: 120),
        Platform(id: 2, x: 160, y: 240)
    ]

    /// Друга платформа недосяжна: гравець, що зсувається вбік, падає.
    private let unreachable = [
        Platform(id: 0, x: 160, y: 0),
        Platform(id: 1, x: 160, y: 5000)
    ]

    private func play(_ session: GameSession, input: Double = 0, seconds: Double = 20) {
        let deltaTime = 1.0 / 60.0
        var time = 0.0
        while time < seconds && session.outcome == .playing {
            session.step(deltaTime: deltaTime, input: input)
            time += deltaTime
        }
    }

    @Test func reachingTopPlatformWins() {
        let spy = SpyObserver()
        let session = GameSession(playerName: "Doodler", platforms: tower,
                                  observers: [spy], completesAtTop: true)
        #expect(session.topHeight == 240)

        play(session)

        #expect(session.outcome == .won)
        #expect(session.progress == 1)
        #expect(session.player.isAlive)
        guard case .levelCompleted? = spy.events.last else {
            Issue.record("Останньою має бути подія levelCompleted")
            return
        }
    }

    @Test func fallingLoses() {
        let session = GameSession(playerName: "Doodler", platforms: unreachable,
                                  completesAtTop: true)

        play(session, input: 1)

        #expect(session.outcome == .lost)
        #expect(!session.player.isAlive)
    }

    @Test func stepDoesNothingAfterGameEnds() {
        let session = GameSession(playerName: "Doodler", platforms: tower, completesAtTop: true)
        play(session)
        let height = session.maxHeight
        let time = session.elapsedTime

        session.step(deltaTime: 1.0 / 60.0, input: 1)

        #expect(session.maxHeight == height)
        #expect(session.elapsedTime == time)
    }

    @Test func simulationModeIgnoresTopPlatform() {
        // Без completesAtTop поведінка як у демо-сценарії: гра не закінчується на верхній платформі
        let session = GameSession(playerName: "Doodler", platforms: DemoLevelProvider().makeLevel())
        session.run(duration: 8)

        #expect(session.outcome == .playing)
        #expect(session.maxHeight > session.topHeight)
    }

    @Test func progressGrowsWithHeight() {
        let session = GameSession(playerName: "Doodler", platforms: unreachable, completesAtTop: true)
        #expect(session.progress == 0)

        // перший кадр — відштовхування від стартової платформи, далі гравець летить угору
        for _ in 0..<20 {
            session.step(deltaTime: 1.0 / 60.0)
        }

        #expect(session.progress > 0)
        #expect(session.progress < 1)
    }

    /// Платформа на всю ширину далеко внизу — «підлога», якої не видно на екрані.
    private let hiddenFloor = [
        Platform(id: 0, x: 160, y: 0),
        Platform(id: 1, x: 0, y: -300, width: GameConfig.worldWidth)
    ]

    @Test func fallBelowScreenLosesBeforeHiddenFloor() {
        let rules = GameplayViewModel.gameplayRules(from: .standard)
        let session = GameSession(playerName: "Doodler", platforms: hiddenFloor,
                                  rules: rules, completesAtTop: true)

        play(session, input: 1, seconds: 5)

        #expect(session.outcome == .lost)
    }

    @Test func simulationRulesStillBounceFromLowPlatform() {
        // Зі стандартною межею падіння (700) гравець встигає приземлитися на нижню платформу
        let session = GameSession(playerName: "Doodler", platforms: hiddenFloor, completesAtTop: true)

        play(session, input: 1, seconds: 5)

        #expect(session.outcome == .playing)
    }

    @Test func feetOnPlatformEdgeLand() {
        let platform = [Platform(id: 0, x: 160, y: 0)]   // 160…240
        let edge = Vector2(x: 250, y: 50)                // центр на 10 правіше краю

        let withFeet = GameSession(playerName: "Doodler", platforms: platform,
                                   completesAtTop: true, footWidth: GameRound.footWidth)
        withFeet.player.position = edge
        let centerOnly = GameSession(playerName: "Doodler", platforms: platform, completesAtTop: true)
        centerOnly.player.position = edge

        for _ in 0..<30 {
            withFeet.step(deltaTime: 1.0 / 60.0)
            centerOnly.step(deltaTime: 1.0 / 60.0)
        }

        #expect(withFeet.player.jumpsCount == 1)
        #expect(centerOnly.player.jumpsCount == 0)
    }

    @Test func feetMissingPlatformFall() {
        let platform = [Platform(id: 0, x: 160, y: 0)]
        let session = GameSession(playerName: "Doodler", platforms: platform,
                                  completesAtTop: true, footWidth: GameRound.footWidth)
        session.player.position = Vector2(x: 270, y: 50)  // ноги 258…282 — повз платформу

        for _ in 0..<30 {
            session.step(deltaTime: 1.0 / 60.0)
        }

        #expect(session.player.jumpsCount == 0)
    }
}
