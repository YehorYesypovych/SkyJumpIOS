import SwiftUI

/// Екран деталей рівня. Показує актуальні дані з ViewModel і передає їй дії користувача.
struct LevelDetailView: View {
    @State private var viewModel: LevelDetailViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: LevelDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let level = viewModel.level {
                content(for: level)
            } else {
                ContentUnavailableView {
                    Label("Рівень не знайдено", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("Можливо, його видалили.")
                } actions: {
                    Button("До списку") { viewModel.backToList() }
                        .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Рівень")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for level: LevelPreset) -> some View {
        List {
            Section("Параметри") {
                LabeledContent("Складність", value: level.difficulty.title)
                LabeledContent("Платформ", value: "\(level.platformCount)")
                LabeledContent("Seed", value: "\(level.seed)")
            }

            Section("Результати") {
                LabeledContent("Рекорд", value: viewModel.bestScoreText)
                LabeledContent("Зіграно ігор", value: "\(level.playsCount)")
            }

            Section {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        viewModel.toggleStats()
                    }
                } label: {
                    HStack {
                        Text("Склад рівня")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(viewModel.isStatsExpanded ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityValue(viewModel.isStatsExpanded ? "розгорнуто" : "згорнуто")

                if viewModel.isStatsExpanded {
                    ForEach(viewModel.platformStats, id: \.0) { type, count in
                        LabeledContent(type.title.capitalized, value: "\(count)")
                            .transition(statsTransition)
                    }
                }
            }

            Section {
                Button {
                    viewModel.play()
                } label: {
                    Label("Грати", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(level.name)
        .toolbar {
            Button("Редагувати") { viewModel.edit() }
        }
    }

    /// Рядки складу «виїжджають» згори; з Reduce Motion — лише плавна поява.
    private var statsTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let library = LevelLibrary()
    NavigationStack {
        LevelDetailView(viewModel: LevelDetailViewModel(levelID: library.levels[1].id,
                                                        library: library,
                                                        navigator: router))
    }
}
