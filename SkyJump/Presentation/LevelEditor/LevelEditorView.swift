import SwiftUI

/// Каркас модального редактора рівня; повний екран — частина B.
struct LevelEditorView: View {
    @State private var viewModel: LevelEditorViewModel

    init(viewModel: LevelEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Text("Редактор рівня — у розробці (частина B)")
    }
}
