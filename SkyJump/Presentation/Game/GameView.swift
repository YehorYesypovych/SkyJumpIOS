import SwiftUI

/// Екран гри: після короткої паузи запускає симуляцію і анімовано показує результат.
struct GameView: View {
    @State private var viewModel: GameViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: GameViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.level == nil {
                ContentUnavailableView {
                    Label("Рівень не знайдено", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("Можливо, його видалили.")
                } actions: {
                    Button("До списку") { viewModel.backToList() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        scoreCard
                        if viewModel.hasResult {
                            resultDetails
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            ProgressView("Симуляція…")
                                .frame(maxWidth: .infinity)
                        }
                        navigationButtons
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await runOnce() }
    }

    // MARK: - Частини екрана

    private var scoreCard: some View {
        VStack(spacing: 8) {
            Text("Рахунок")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(viewModel.score)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(viewModel.score)))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if viewModel.isNewRecord {
                Label("Новий рекорд!", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.green, in: Capsule())
                    .transition(recordTransition)
            }

            if let level = viewModel.level {
                Text("Рекорд рівня: \(level.bestScore) · ігор: \(level.playsCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private var resultDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let summary = viewModel.summaryText {
                Text(summary)
                    .font(.callout)
            }

            Button {
                withAnimation(reduceMotion ? nil : Animation.snappy) {
                    viewModel.toggleLog()
                }
            } label: {
                HStack {
                    Text("Журнал подій (\(viewModel.logLines.count))")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(viewModel.isLogExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }

            if viewModel.isLogExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { item in
                        Text(item.element)
                            .font(.system(.footnote, design: .monospaced))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.backToLevel()
            } label: {
                Text("До рівня").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                viewModel.backToList()
            } label: {
                Text("До списку").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
    }

    // MARK: - Анімація результату

    /// Бейдж рекорду «вистрибує» з пружиною; з увімкненим Reduce Motion — лише плавна поява.
    private var recordTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity)
    }

    /// Запускає гру один раз за життя екрана. Пауза дає побачити стан «Симуляція…»,
    /// а зміна стану в withAnimation анімує рахунок, бейдж рекорду і появу підсумку.
    /// Кнопки весь час доступні: анімується лише відображення, стан змінюється одразу.
    private func runOnce() async {
        guard !viewModel.hasResult else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.35)) {
            viewModel.start()
        }
    }
}

#Preview {
    let dependencies = AppDependencies.previewWithRealSimulation()
    NavigationStack {
        GameView(viewModel: GameViewModel(levelID: dependencies.library.levels[0].id,
                                          library: dependencies.library,
                                          simulator: dependencies.simulator,
                                          scoreStore: dependencies.scoreStore,
                                          navigator: AppRouter()))
    }
}
