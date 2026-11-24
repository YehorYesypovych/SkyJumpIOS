import Testing
@testable import SkyJump

@MainActor
struct LevelEditorViewModelTests {

    @Test func emptyOrWhitespaceNameCannotBeSaved() {
        let navigator = SpyNavigator()
        let viewModel = LevelEditorViewModel(mode: .create, library: LevelLibrary(), navigator: navigator)

        viewModel.draft.name = ""
        #expect(!viewModel.canSave)
        #expect(viewModel.validationMessage != nil)

        viewModel.draft.name = "   "
        #expect(!viewModel.canSave)

        viewModel.draft.name = "Мій рівень"
        #expect(viewModel.canSave)
        #expect(viewModel.validationMessage == nil)
    }

    @Test func tooLongNameAndPlatformCountOutOfRangeCannotBeSaved() {
        let navigator = SpyNavigator()
        let viewModel = LevelEditorViewModel(mode: .create, library: LevelLibrary(), navigator: navigator)

        viewModel.draft.name = String(repeating: "a", count: LevelPreset.maxNameLength + 1)
        #expect(!viewModel.canSave)

        viewModel.draft.name = "Рівень"
        viewModel.draft.platformCount = LevelPreset.platformCountRange.upperBound + 1
        #expect(!viewModel.canSave)
    }

    @Test func saveInCreateModeAddsLevelAndDismisses() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelEditorViewModel(mode: .create, library: library, navigator: navigator)
        let countBefore = library.levels.count

        viewModel.draft.name = "  Новий  "
        viewModel.draft.platformCount = 12
        viewModel.draft.difficulty = .hard
        viewModel.save()

        #expect(library.levels.count == countBefore + 1)
        let added = library.levels.last
        #expect(added?.name == "Новий")
        #expect(added?.platformCount == 12)
        #expect(added?.difficulty == .hard)
        #expect(navigator.calls == ["dismissSheet"])
    }

    @Test func saveInEditModeUpdatesExistingLevel() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let original = library.levels[0]
        let viewModel = LevelEditorViewModel(mode: .edit(original.id), library: library, navigator: navigator)

        #expect(viewModel.draft == original)
        #expect(!viewModel.hasChanges)

        viewModel.draft.name = "Оновлений"
        viewModel.draft.platformCount = 25
        #expect(viewModel.hasChanges)
        // до збереження бібліотека не змінюється — редагується копія
        #expect(library.level(id: original.id)?.name == original.name)

        viewModel.save()

        #expect(library.levels.count == LevelPreset.samples.count)
        #expect(library.level(id: original.id)?.name == "Оновлений")
        #expect(library.level(id: original.id)?.platformCount == 25)
        #expect(navigator.calls == ["dismissSheet"])
    }

    @Test func cancelDoesNotChangeLibrary() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let original = library.levels[1]
        let viewModel = LevelEditorViewModel(mode: .edit(original.id), library: library, navigator: navigator)

        viewModel.draft.name = "Не зберігати"
        viewModel.regenerateSeed()
        viewModel.cancel()

        #expect(library.levels == LevelPreset.samples)
        #expect(library.level(id: original.id) == original)
        #expect(navigator.calls == ["dismissSheet"])
    }

    @Test func invalidDraftIsNotSaved() {
        let library = LevelLibrary()
        let navigator = SpyNavigator()
        let viewModel = LevelEditorViewModel(mode: .create, library: library, navigator: navigator)

        viewModel.save()

        #expect(library.levels.count == LevelPreset.samples.count)
        #expect(navigator.calls.isEmpty)
    }
}
