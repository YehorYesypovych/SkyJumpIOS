import SwiftUI

/// Корінь застосунку: список рівнів. Переходи виконує роутер через ViewModel.
struct LevelListView: View {
    @State private var viewModel: LevelListViewModel

    init(viewModel: LevelListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.levels) { level in
                Button {
                    viewModel.open(level.id)
                } label: {
                    LevelRow(title: level.name,
                             subtitle: viewModel.subtitle(for: level),
                             record: viewModel.recordText(for: level))
                }
            }
            .onDelete { offsets in
                viewModel.delete(at: offsets)
            }
        }
        .overlay {
            if viewModel.isEmpty {
                ContentUnavailableView("Ще немає рівнів",
                                       systemImage: "square.stack.3d.up.slash",
                                       description: Text("Натисніть «+», щоб створити свій рівень."))
            }
        }
        .animation(.default, value: viewModel.levels)
        .navigationTitle("Мої рівні")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Демо", systemImage: "play.rectangle") {
                    viewModel.openDemo()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Додати рівень", systemImage: "plus") {
                    viewModel.create()
                }
            }
        }
    }
}

/// Рядок списку. Текст іде стовпчиком, щоб на вузьких екранах і з великим шрифтом нічого не перекривалось.
private struct LevelRow: View {
    let title: String
    let subtitle: String
    let record: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(record)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

#Preview("Список") {
    // Роутер тримається тут, бо ViewModel зберігає навігатор слабким посиланням
    @Previewable @State var router = AppRouter()
    NavigationStack {
        LevelListView(viewModel: LevelListViewModel(library: LevelLibrary(),
                                                    navigator: router))
    }
}

#Preview("Порожній список") {
    @Previewable @State var router = AppRouter()
    NavigationStack {
        LevelListView(viewModel: LevelListViewModel(library: LevelLibrary(levels: []),
                                                    navigator: router))
    }
}
