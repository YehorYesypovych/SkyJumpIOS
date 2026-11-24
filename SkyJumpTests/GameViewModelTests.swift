import Foundation
import Testing
@testable import SkyJump

@MainActor
struct GameViewModelTests {

    private func makeViewModel(levelID: LevelPreset.ID,
                               library: LevelLibrary,
                               scoreStore: InMemoryScoreStore,
                               navigator: SpyNavigator) -> GameViewModel {
        GameViewModel(levelID: levelID,
                      library: library,
                      simulator: GameSimulationService(),
                      scoreStore: scoreStore,
                      navigator: navigator)
    }

    @Test func startRecordsResultInLibrary() {
        let library = LevelLibrary()
        let store = InMemoryScoreStore()
        let navigator = SpyNavigator()
        let levelID = library.levels[0].id
        let viewModel = makeViewModel(levelID: levelID, library: library,
                                      scoreStore: store, navigator: navigator)

        viewModel.start()

        #expect(viewModel.hasResult)
        #expect(viewModel.score > 0)
        #expect(viewModel.isNewRecord)
        #expect(viewModel.summaryText != nil)
        #expect(!viewModel.logLines.isEmpty)
        #expect(library.level(id: levelID)?.bestScore == viewModel.score)
        #expect(library.level(id: levelID)?.playsCount == 1)
        #expect(store.bestScore == viewModel.score)
    }

    @Test func sameResultIsNotNewRecord() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let levelID = library.levels[0].id
        let viewModel = makeViewModel(levelID: levelID, library: library,
                                      scoreStore: InMemoryScoreStore(), navigator: navigator)

        viewModel.start()
        viewModel.start()   // той самий пресет дає той самий результат

        #expect(!viewModel.isNewRecord)
        #expect(library.level(id: levelID)?.playsCount == 2)
    }

    @Test func missingLevelDoesNotStart() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(levelID: UUID(), library: library,
                                      scoreStore: InMemoryScoreStore(), navigator: navigator)

        viewModel.start()

        #expect(viewModel.level == nil)
        #expect(!viewModel.hasResult)
    }

    @Test func navigationGoesThroughNavigator() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = makeViewModel(levelID: library.levels[0].id, library: library,
                                      scoreStore: InMemoryScoreStore(), navigator: navigator)

        viewModel.backToLevel()
        viewModel.backToList()

        #expect(navigator.calls == ["pop", "popToRoot"])
    }
}
