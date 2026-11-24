import Testing
@testable import SkyJump

@MainActor
struct LevelDetailViewModelTests {

    @Test func levelReflectsLibraryUpdates() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        var level = library.levels[0]
        let viewModel = LevelDetailViewModel(levelID: level.id, library: library, navigator: navigator)

        level.name = "Нова назва"
        level.platformCount = 40
        library.update(level)

        #expect(viewModel.level?.name == "Нова назва")
        #expect(viewModel.level?.platformCount == 40)
    }

    @Test func levelReflectsRecordedResult() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let id = library.levels[0].id
        let viewModel = LevelDetailViewModel(levelID: id, library: library, navigator: navigator)
        #expect(viewModel.bestScoreText == "ще не грали")

        library.recordResult(levelID: id, score: 750)

        #expect(viewModel.level?.bestScore == 750)
        #expect(viewModel.level?.playsCount == 1)
        #expect(viewModel.bestScoreText == "750")
    }

    @Test func deletedLevelIsNil() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let id = library.levels[0].id
        let viewModel = LevelDetailViewModel(levelID: id, library: library, navigator: navigator)

        library.delete(id: id)

        #expect(viewModel.level == nil)
        #expect(viewModel.platformStats.isEmpty)
    }

    @Test func platformStatsMatchPreset() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let level = library.levels[0] // «Розминка», легкий: лише звичайні й пружини
        let viewModel = LevelDetailViewModel(levelID: level.id, library: library, navigator: navigator)

        let stats = viewModel.platformStats
        #expect(stats.map(\.1).reduce(0, +) == level.platformCount)
        #expect(stats.allSatisfy { level.difficulty.allowedTypes.contains($0.0) })
    }

    @Test func toggleStatsSwitchesExpansion() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelDetailViewModel(levelID: library.levels[0].id, library: library, navigator: navigator)

        #expect(!viewModel.isStatsExpanded)
        viewModel.toggleStats()
        #expect(viewModel.isStatsExpanded)
        viewModel.toggleStats()
        #expect(!viewModel.isStatsExpanded)
    }

    @Test func editAndPlayAskNavigator() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelDetailViewModel(levelID: library.levels[0].id, library: library, navigator: navigator)

        viewModel.edit()
        viewModel.play()

        #expect(navigator.calls == ["presentEditLevel", "startGame"])
    }

    @Test func simulationAsksNavigator() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelDetailViewModel(levelID: library.levels[0].id, library: library, navigator: navigator)

        viewModel.simulate()

        #expect(navigator.calls == ["simulateLevel"])
    }
}

@MainActor
struct LevelDetailStatsCacheTests {

    @Test func statsChangeOnlyWithGenerationParameters() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        var level = library.levels[1]
        let viewModel = LevelDetailViewModel(levelID: level.id, library: library, navigator: navigator)
        let initial = viewModel.platformStats.map(\.1).reduce(0, +)
        #expect(initial == level.platformCount)

        level.name = "Інша назва"            // не впливає на генерацію — береться збережений результат
        library.update(level)
        #expect(viewModel.platformStats.map(\.1).reduce(0, +) == level.platformCount)

        level.platformCount = 12             // впливає — рівень перераховується
        library.update(level)
        #expect(viewModel.platformStats.map(\.1).reduce(0, +) == 12)
    }
}
