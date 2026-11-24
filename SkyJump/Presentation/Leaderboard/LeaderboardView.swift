import SwiftUI

/// Каркас екрана «Лідери»; повний екран — частина B.
struct LeaderboardView: View {
    @State private var viewModel: LeaderboardViewModel

    init(viewModel: LeaderboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Text("Таблиця лідерів — у розробці (частина B)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appBackground()
            .navigationTitle("Лідери")
    }
}
