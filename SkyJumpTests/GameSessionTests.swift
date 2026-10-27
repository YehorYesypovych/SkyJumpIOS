import Testing
@testable import SkyJump

@MainActor
struct GameSessionTests {

    @Test func observerReceivesJumpAndBreakEvents() {
        let spy = SpyObserver()
        let session = GameSession(playerName: "Doodler",
                                  platforms: DemoLevelProvider().makeLevel(),
                                  observers: [spy])
        session.run(duration: 8)

        let jumpsCount = spy.events.filter {
            if case .jumped = $0 { return true } else { return false }
        }.count
        let brokenIDs = spy.events.compactMap { event -> Int? in
            if case let .platformBroken(platformID) = event { return platformID } else { return nil }
        }

        guard case let .started(playerName, platformCount)? = spy.events.first else {
            Issue.record("Першою має бути подія started")
            return
        }
        #expect(playerName == "Doodler")
        #expect(platformCount == 10)
        #expect(jumpsCount == 10)
        #expect(brokenIDs == [4])

        guard case .finished? = spy.events.last else {
            Issue.record("Останньою має бути подія finished")
            return
        }
    }

    @Test func observerAddedLaterReceivesEvents() {
        let spy = SpyObserver()
        let session = GameSession(playerName: "Doodler", platforms: TestLevelProvider().makeLevel())
        session.addObserver(spy)
        session.run(duration: 1)

        #expect(!spy.events.isEmpty)
    }

    @Test func customLandingStrategyIsUsedWithoutChangingSession() {
        let strategy = CountingBreakLanding()
        let session = GameSession(playerName: "Doodler",
                                  platforms: TestLevelProvider().makeLevel(),
                                  landingStrategies: [.normal: strategy])
        session.run(duration: 3)

        let summary = session.makeSummary()
        #expect(strategy.landingsCount > 0)
        #expect(summary.jumpsCount == 0)
        #expect(summary.brokenPlatformsCount == strategy.landingsCount)
    }

    @Test func rulesArePassedThroughInit() {
        let level = DemoLevelProvider().makeLevel()
        let lowGravity = GameRules(gravity: -1000, jumpVelocity: 750,
                                   springMultiplier: 1.6, screenHeight: 700)

        let standard = GameSimulationService().simulate(playerName: "Doodler", level: level, duration: 8)
        let custom = GameSimulationService(rules: lowGravity)
            .simulate(playerName: "Doodler", level: level, duration: 8)

        #expect(standard.summary.score == 1291)
        #expect(custom.summary.score != standard.summary.score)
    }
}
