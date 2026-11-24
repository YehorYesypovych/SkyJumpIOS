import Foundation
import Testing
@testable import SkyJump

@MainActor
struct GameRoundTests {

    /// Платформи одна над одною: без керування гравець доходить до верху.
    private static let tower = [
        Platform(id: 0, x: 160, y: 0),
        Platform(id: 1, x: 160, y: 120),
        Platform(id: 2, x: 160, y: 240)
    ]

    private func makeRound(library: LevelLibrary,
                           store: InMemoryScoreStore,
                           levelID: LevelPreset.ID? = nil) -> GameRound {
        GameRound(levelID: levelID ?? library.levels[0].id,
                  library: library,
                  scoreStore: store,
                  makeLevel: { _ in GameRoundTests.tower })
    }

    private func playToEnd(_ round: GameRound) {
        var frames = 0
        while round.outcome == .playing && frames < 60 * 20 {
            round.session?.step(deltaTime: 1.0 / 60.0)
            frames += 1
        }
    }

    @Test func winRecordsResultOnce() {
        let library = LevelLibrary()
        let store = InMemoryScoreStore()
        let round = makeRound(library: library, store: store)
        round.start()
        #expect(!round.finishIfNeeded())   // гра ще триває

        playToEnd(round)

        #expect(round.outcome == .won)
        #expect(round.finishIfNeeded())
        #expect(!round.finishIfNeeded())   // вдруге не записує
        #expect(round.isNewRecord)
        #expect(round.isFinished)

        let level = library.levels[0]
        #expect(level.playsCount == 1)
        #expect(level.bestScore == round.session?.score)
        #expect(store.bestScore == round.session?.score)
    }

    @Test func secondRoundWithSameScoreIsNotRecord() {
        let library = LevelLibrary()
        let round = makeRound(library: library, store: InMemoryScoreStore())

        round.start()
        playToEnd(round)
        round.finishIfNeeded()

        round.start()
        #expect(!round.isFinished)
        #expect(!round.isNewRecord)
        #expect(round.outcome == .playing)

        playToEnd(round)
        round.finishIfNeeded()

        #expect(!round.isNewRecord)
        #expect(library.levels[0].playsCount == 2)
    }

    @Test func unknownLevelHasNoSession() {
        let round = makeRound(library: LevelLibrary(), store: InMemoryScoreStore(), levelID: UUID())
        round.start()

        #expect(round.session == nil)
        #expect(round.level == nil)
        #expect(!round.finishIfNeeded())
    }

    @Test func presetLevelIsUsedByDefault() {
        let library = LevelLibrary()
        let level = library.levels[1]
        let round = GameRound(levelID: level.id, library: library, scoreStore: InMemoryScoreStore())
        round.start()

        #expect(round.session?.platforms.count == level.platformCount)
    }
}
