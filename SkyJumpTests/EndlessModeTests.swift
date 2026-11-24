import Foundation
import Testing
@testable import SkyJump

@MainActor
struct EndlessModeTests {

    @Test func generatorKeepsLevelReachable() {
        let generator = EndlessLevelGenerator(seed: 42)
        let start = generator.start()
        let more = generator.extend(upTo: 20_000)
        let platforms = start.platforms + more.platforms

        #expect(platforms.first?.position.y == 0)
        #expect(generator.topHeight >= 20_000)
        // між сусідніми платформами завжди менше, ніж висота стрибка (~187)
        let heights = platforms.map(\.position.y)
        let gaps = zip(heights.dropFirst(), heights).map { $0 - $1 }
        #expect(gaps.allSatisfy { $0 > 0 && $0 <= 150 })
        // id не повторюються
        #expect(Set(platforms.map(\.id)).count == platforms.count)
    }

    @Test func generatorGetsHarderWithHeight() {
        let generator = EndlessLevelGenerator(seed: 7)
        let low = generator.start().platforms
        let high = generator.extend(upTo: 12_000).platforms.filter { $0.position.y > 8_000 }

        func trickyShare(_ platforms: [Platform]) -> Double {
            let tricky = platforms.filter { $0.type == .moving || $0.type == .breakable }.count
            return Double(tricky) / Double(max(platforms.count, 1))
        }
        #expect(trickyShare(high) > trickyShare(low))
        #expect(!low.contains { $0.type == .breakable && $0.position.y < 1_000 })
        #expect(EndlessLevelGenerator.step(atHeight: 0) < EndlessLevelGenerator.step(atHeight: 10_000))
    }

    @Test func endlessRoundGrowsLevelAndRecordsOwnScore() {
        let library = LevelLibrary()
        let endless = InMemoryScoreStore()
        let round = GameRound(mode: .endless, library: library, scoreStore: InMemoryScoreStore(),
                              endlessScores: endless)
        round.start()
        let session = round.session!
        let initialTop = session.platforms.map(\.position.y).max() ?? 0

        // штучно піднімаємо гравця: рівень має добудуватися вище
        session.player.position = Vector2(x: 200, y: initialTop)
        session.step(deltaTime: 1.0 / 60.0)
        round.extendIfNeeded()
        let newTop = session.platforms.map(\.position.y).max() ?? 0
        #expect(newTop > initialTop)

        // падіння завершує гру, рекорд іде в окреме сховище, бібліотека рівнів не змінюється
        session.player.position = Vector2(x: 200, y: -5_000)
        session.step(deltaTime: 1.0 / 60.0)
        #expect(round.outcome == .lost)
        #expect(round.finishIfNeeded())
        #expect(endless.bestScore == session.score)
        #expect(library.levels.allSatisfy { $0.playsCount == 0 })
        #expect(round.bestScore == endless.bestScore)
    }

    @Test func endlessViewModelHasTitleAndNoLevel() {
        let navigator = SpyNavigator()
        let viewModel = GameplayViewModel(mode: .endless, library: LevelLibrary(),
                                          scoreStore: InMemoryScoreStore(),
                                          endlessScores: InMemoryScoreStore(bestScore: 1_234),
                                          navigator: navigator)
        viewModel.start()

        #expect(viewModel.hasStarted)
        #expect(!viewModel.isUnavailable)
        #expect(viewModel.title == "Нескінченний режим")
        #expect(viewModel.bestScore == 1_234)
    }

    @Test func listOpensEndless() {
        let navigator = SpyNavigator()
        let viewModel = LevelListViewModel(library: LevelLibrary(), navigator: navigator,
                                           endlessScores: InMemoryScoreStore(bestScore: 900))
        viewModel.startEndless()

        #expect(navigator.calls == ["startEndless"])
        #expect(viewModel.endlessSubtitle == "Рекорд: 900")
    }

    @Test func routerPushesEndless() {
        let router = AppRouter()
        router.startEndless()
        #expect(router.path == [.endless])
    }
}

@MainActor
struct ScoreReportingTests {

    private static let tower = [
        Platform(id: 0, x: 160, y: 0),
        Platform(id: 1, x: 160, y: 120),
        Platform(id: 2, x: 160, y: 240)
    ]

    @Test func levelModeDoesNotReport() {
        let library = LevelLibrary()
        let reporter = SpyScoreReporter()
        let navigator = SpyNavigator()
        let viewModel = GameplayViewModel(mode: .level(library.levels[0].id), library: library,
                                          scoreStore: InMemoryScoreStore(), endlessScores: InMemoryScoreStore(),
                                          navigator: navigator, scoreReporter: reporter,
                                          makeLevel: { _ in ScoreReportingTests.tower })
        viewModel.start()
        for _ in 0..<(60 * 10) {
            viewModel.tick(deltaTime: 1.0 / 60.0)
        }

        #expect(viewModel.outcome == .won)
        #expect(reporter.reportedScores.isEmpty)
    }

    @Test func routerOpensLeaderboard() {
        let router = AppRouter()
        router.showLeaderboard()
        #expect(router.path == [.leaderboard])
    }
}
