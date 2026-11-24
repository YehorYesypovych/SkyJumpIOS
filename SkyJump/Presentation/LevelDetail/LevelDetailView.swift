import SwiftUI

/// Каркас екрана деталей рівня; повний екран — частина B.
struct LevelDetailView: View {
    @State private var viewModel: LevelDetailViewModel

    init(viewModel: LevelDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Text("Деталі рівня — у розробці (частина B)")
            .navigationTitle("Рівень")
    }
}
