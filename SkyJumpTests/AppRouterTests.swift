import Foundation
import Testing
@testable import SkyJump

@MainActor
struct AppRouterTests {

    @Test func pushAndPopRoutes() {
        let router = AppRouter()
        let id = UUID()

        router.showLevel(id)
        router.startGame(id)
        #expect(router.path == [.levelDetail(id), .game(id)])

        router.pop()
        #expect(router.path == [.levelDetail(id)])
    }

    @Test func popOnEmptyStackDoesNothing() {
        let router = AppRouter()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test func popToRootClearsStack() {
        let router = AppRouter()
        let id = UUID()
        router.showLevel(id)
        router.startGame(id)
        router.showDemo()

        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test func sheetIsPresentedAndDismissed() {
        let router = AppRouter()
        let id = UUID()

        router.presentEditLevel(id)
        #expect(router.sheet == .editLevel(id))

        router.dismissSheet()
        #expect(router.sheet == nil)

        router.presentCreateLevel()
        #expect(router.sheet == .createLevel)
    }

    @Test func sheetDoesNotChangeStack() {
        let router = AppRouter()
        let id = UUID()
        router.showLevel(id)

        router.presentEditLevel(id)
        router.dismissSheet()
        #expect(router.path == [.levelDetail(id)])
    }
}
