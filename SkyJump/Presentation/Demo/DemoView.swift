import SwiftUI

/// Екран демо-сценарію. Лише показує стан ViewModel і передає їй дії користувача.
struct DemoView: View {
    @State private var viewModel: DemoViewModel

    init(viewModel: DemoViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Запустити демо-сценарій") {
                viewModel.runDemo()
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Text("Рекорд: \(viewModel.bestScore)")
                    .font(.headline)
                if viewModel.isNewRecord {
                    Text("Новий рекорд!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
            }

            if let summary = viewModel.summaryText {
                Text(summary)
                    .font(.callout)
            }

            List(Array(viewModel.logLines.enumerated()), id: \.offset) { item in
                Text(item.element)
                    .font(.system(.footnote, design: .monospaced))
            }
            .listStyle(.plain)
        }
        .padding()
        .navigationTitle("Демо-сценарій")
    }
}

#Preview("Стаби") {
    NavigationStack {
        DemoView(viewModel: AppDependencies.preview().makeDemoViewModel())
    }
}

#Preview("Справжня симуляція, тестовий рівень") {
    NavigationStack {
        DemoView(viewModel: AppDependencies.previewWithRealSimulation().makeDemoViewModel())
    }
}
