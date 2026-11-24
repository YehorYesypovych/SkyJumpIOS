import Foundation
import Testing
@testable import SkyJump

@MainActor
struct GameplayViewModelTests {

    private static let tower = [
        Platform(id: 0, x: 160, y: 0),
        Platform(id: 1, x: 160, y: 120),
        Platform(id: 2, x: 160, y: 240)
    ]

    private func makeViewModel(library: LevelLibrary,
                               navigator: SpyNavigator,
                               levelID: LevelPreset.ID? = nil) -> GameplayViewModel {
        GameplayViewModel(levelID: levelID ?? library.levels[0].id,
                          library: library,
                          scoreStore: InMemoryScoreStore(),
                          navigator: navigator,
                          makeLevel: { _ in GameplayViewModelTests.tower })
    }

    private func run(_ viewModel: GameplayViewModel, frames: Int) {
        for _ in 0..<frames {
            viewModel.tick(deltaTime: 1.0 / 60.0)
        }
    }

    @Test func startPreparesFirstFrame() {
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: LevelLibrary(), navigator: navigator)

        viewModel.start()

        #expect(viewModel.hasStarted)
        #expect(viewModel.outcome == .playing)
        #expect(viewModel.frame.platforms.count == 3)
        #expect(viewModel.frame.playerX == 200)
    }

    @Test func pausedGameDoesNotMove() {
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: LevelLibrary(), navigator: navigator)
        viewModel.start()
        run(viewModel, frames: 5)

        viewModel.pause()
        let pausedFrame = viewModel.frame
        run(viewModel, frames: 30)
        #expect(viewModel.frame == pausedFrame)

        viewModel.resume()
        run(viewModel, frames: 5)
        #expect(viewModel.frame != pausedFrame)
    }

    @Test func inputMovesPlayerSideways() {
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: LevelLibrary(), navigator: navigator)
        viewModel.start()

        viewModel.setInput(1)
        run(viewModel, frames: 10)

        #expect(viewModel.frame.playerX > 200)
    }

    @Test func reachingTopWinsAndUpdatesRecord() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: library, navigator: navigator)
        viewModel.start()

        run(viewModel, frames: 60 * 10)

        #expect(viewModel.outcome == .won)
        #expect(viewModel.isNewRecord)
        #expect(viewModel.bestScore == viewModel.frame.score)
        #expect(library.levels[0].playsCount == 1)
    }

    @Test func restartResetsRound() {
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: LevelLibrary(), navigator: navigator)
        viewModel.start()
        run(viewModel, frames: 60 * 10)

        viewModel.restart()

        #expect(viewModel.outcome == .playing)
        #expect(!viewModel.isNewRecord)
        #expect(viewModel.frame.score == 0)
    }

    @Test func missingLevelDoesNotStart() {
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: LevelLibrary(), navigator: navigator, levelID: UUID())

        viewModel.start()
        run(viewModel, frames: 10)

        #expect(viewModel.level == nil)
        #expect(!viewModel.hasStarted)
    }

    @Test func navigationGoesThroughNavigator() {
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(library: LevelLibrary(), navigator: navigator)

        viewModel.backToLevel()
        viewModel.backToList()

        #expect(navigator.calls == ["pop", "popToRoot"])
    }
}
