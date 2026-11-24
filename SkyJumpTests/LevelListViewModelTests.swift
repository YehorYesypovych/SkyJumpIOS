import Foundation
import Testing
@testable import SkyJump

@MainActor
struct LevelListViewModelTests {

    @Test func actionsGoThroughNavigator() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelListViewModel(library: library, navigator: navigator)

        viewModel.open(library.levels[0].id)
        viewModel.create()
        viewModel.openDemo()
        viewModel.openRadio()
        viewModel.openCustomize()

        #expect(navigator.calls == ["showLevel", "presentCreateLevel", "showDemo", "showRadio", "showCustomize"])
    }

    @Test func deleteRemovesLevelFromLibrary() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelListViewModel(library: library, navigator: navigator)
        let firstID = library.levels[0].id

        viewModel.delete(at: IndexSet(integer: 0))

        #expect(viewModel.levels.count == 2)
        #expect(library.level(id: firstID) == nil)
    }

    @Test func listReflectsLibraryChanges() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelListViewModel(library: library, navigator: navigator)
        var level = library.levels[0]
        level.name = "Змінена назва"

        library.update(level)
        library.recordResult(levelID: level.id, score: 640)

        #expect(viewModel.levels[0].name == "Змінена назва")
        #expect(viewModel.recordText(for: viewModel.levels[0]) == "Рекорд: 640 · ігор: 1")
    }
}
