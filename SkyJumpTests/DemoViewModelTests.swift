import Testing
@testable import SkyJump

@MainActor
struct DemoViewModelTests {

    private func makeViewModel(scoreStore: InMemoryScoreStore) -> DemoViewModel {
        DemoViewModel(levelProvider: TestLevelProvider(),
                      simulator: GameSimulationService(),
                      scoreStore: scoreStore)
    }

    @Test func firstRunSetsNewRecord() {
        let store = InMemoryScoreStore()
        let viewModel = makeViewModel(scoreStore: store)
        viewModel.runDemo()

        #expect(viewModel.isNewRecord)
        #expect(viewModel.bestScore > 0)
        #expect(viewModel.bestScore == store.bestScore)
        #expect(!viewModel.logLines.isEmpty)
        #expect(viewModel.summaryText != nil)
    }

    @Test func sameScoreIsNotNewRecord() {
        let viewModel = makeViewModel(scoreStore: InMemoryScoreStore())
        viewModel.runDemo()
        let firstBest = viewModel.bestScore
        viewModel.runDemo()

        #expect(!viewModel.isNewRecord)
        #expect(viewModel.bestScore == firstBest)
    }

    @Test func higherStoredRecordIsKept() {
        let viewModel = makeViewModel(scoreStore: InMemoryScoreStore(bestScore: 1_000_000))
        viewModel.runDemo()

        #expect(!viewModel.isNewRecord)
        #expect(viewModel.bestScore == 1_000_000)
    }
}
