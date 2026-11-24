import SwiftUI

/// Каркас екрана гри; повний екран — частина A.
struct GameView: View {
    @State private var viewModel: GameViewModel

    init(viewModel: GameViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Text("Гра — у розробці (частина A)")
            .navigationTitle("Гра")
    }
}
