import SwiftUI

/// Корінь застосунку: список рівнів. Переходи виконує роутер через ViewModel.
struct LevelListView: View {
    @State private var viewModel: LevelListViewModel

    init(viewModel: LevelListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.levels) { level in
                    Button {
                        viewModel.open(level.id)
                    } label: {
                        LevelCard(level: level,
                                  subtitle: viewModel.subtitle(for: level),
                                  record: viewModel.recordText(for: level))
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete { offsets in
                    viewModel.delete(at: offsets)
                }
            } header: {
                if !viewModel.isEmpty {
                    Text("Тримайся вище, збирай 🚀, не падай")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .appBackground()
        .overlay {
            if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("Ще немає рівнів", systemImage: "square.stack.3d.up.slash")
                } description: {
                    Text("Створи свій перший рівень.")
                } actions: {
                    Button {
                        viewModel.create()
                    } label: {
                        Label("Новий рівень", systemImage: "plus")
                    }
                    .buttonStyle(.gradient)
                    .frame(maxWidth: 240)
                }
            }
        }
        .animation(.default, value: viewModel.levels)
        .navigationTitle("Мої рівні")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Стиль", systemImage: "paintpalette") {
                    viewModel.openCustomize()
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Демо", systemImage: "play.rectangle") {
                    viewModel.openDemo()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Радіо", systemImage: "radio") {
                    viewModel.openRadio()
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

/// Картка рівня: кольорова плитка зі складністю, назва, параметри і рекорд.
/// Текст іде стовпчиком, щоб на вузьких екранах і з великим шрифтом нічого не перекривалось.
private struct LevelCard: View {
    let level: LevelPreset
    let subtitle: String
    let record: String

    var body: some View {
        HStack(spacing: 14) {
            Text(Theme.emoji(for: level.difficulty))
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
                .background(Theme.gradient(for: level.difficulty),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(level.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(record, systemImage: level.bestScore > 0 ? "trophy.fill" : "sparkles")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(level.bestScore > 0 ? Theme.sunsetOrange : .secondary)
                    .labelStyle(.titleAndIcon)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .cardStyle(cornerRadius: 22)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Відкрити рівень")
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
