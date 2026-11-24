import SwiftUI

/// Каркас екрана списку рівнів; повний екран — частина A.
struct LevelListView: View {
    @State private var viewModel: LevelListViewModel

    init(viewModel: LevelListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List(viewModel.levels) { level in
            Button(level.name) {
                viewModel.open(level.id)
            }
        }
        .navigationTitle("Мої рівні")
        .toolbar {
            Button("Додати рівень", systemImage: "plus") {
                viewModel.create()
            }
        }
    }
}
