import SwiftUI

/// Створює екрани з потрібними залежностями. Єдине місце, де View отримують ViewModel.
struct ScreenFactory {
    let dependencies: AppDependencies
    let navigator: AppNavigating

    func makeLevelList() -> some View {
        LevelListView(viewModel: LevelListViewModel(library: dependencies.library,
                                                    navigator: navigator))
            .safeAreaInset(edge: .bottom) {
                MiniPlayerBar(player: dependencies.radio) { [navigator] in
                    navigator.showRadio()
                }
            }
    }

    @ViewBuilder
    func makeView(for route: Route) -> some View {
        switch route {
        case .levelDetail(let id):
            LevelDetailView(viewModel: LevelDetailViewModel(levelID: id,
                                                            library: dependencies.library,
                                                            navigator: navigator))
        case .play(let id):
            GameplayView(viewModel: GameplayViewModel(levelID: id,
                                                      library: dependencies.library,
                                                      scoreStore: dependencies.scoreStore,
                                                      navigator: navigator),
                         radio: dependencies.radio,
                         cosmetics: dependencies.cosmetics)
        case .game(let id):
            GameView(viewModel: GameViewModel(levelID: id,
                                              library: dependencies.library,
                                              simulator: dependencies.simulator,
                                              scoreStore: dependencies.scoreStore,
                                              navigator: navigator))
        case .demo:
            DemoView(viewModel: dependencies.makeDemoViewModel())
        case .customize:
            CustomizeView(settings: dependencies.cosmetics)
        case .radio:
            RadioView(viewModel: RadioViewModel(provider: dependencies.radioProvider,
                                                player: dependencies.radio))
        }
    }

    @ViewBuilder
    func makeView(for sheet: Sheet) -> some View {
        switch sheet {
        case .createLevel:
            LevelEditorView(viewModel: LevelEditorViewModel(mode: .create,
                                                            library: dependencies.library,
                                                            navigator: navigator))
        case .editLevel(let id):
            LevelEditorView(viewModel: LevelEditorViewModel(mode: .edit(id),
                                                            library: dependencies.library,
                                                            navigator: navigator))
        }
    }
}
