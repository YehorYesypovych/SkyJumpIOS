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
        ScrollView {
            VStack(spacing: 16) {
                header(for: level)
                stats(for: level)
                composition
                actions
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .appBackground()
        .navigationTitle(level.name)
        .toolbar {
            Button("Редагувати") { viewModel.edit() }
        }
    }

    /// Велика плитка рівня: складність і seed.
    private func header(for level: LevelPreset) -> some View {
        HStack(spacing: 16) {
            Text(Theme.emoji(for: level.difficulty))
                .font(.system(size: 40))
                .frame(width: 76, height: 76)
                .background(Theme.gradient(for: level.difficulty),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(level.difficulty.title)
                    .font(.title3.weight(.bold))
                Text("Seed \(level.seed)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    /// Три плитки з головними числами рівня.
    private func stats(for level: LevelPreset) -> some View {
        HStack(spacing: 10) {
            statTile(title: "Рекорд", value: viewModel.bestScoreText, symbol: "trophy.fill", tint: Theme.sunsetOrange)
            statTile(title: "Ігор", value: "\(level.playsCount)", symbol: "gamecontroller.fill", tint: Theme.electricBlue)
            statTile(title: "Платформ", value: "\(level.platformCount)", symbol: "square.stack.3d.up.fill", tint: Theme.neonMint)
        }
    }

    private func statTile(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardStyle(cornerRadius: 18)
        .accessibilityElement(children: .combine)
    }

    /// «Склад рівня»: розгортається з анімацією, рядки виїжджають згори.
    private var composition: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy) {
                    viewModel.toggleStats()
                }
            } label: {
                HStack {
                    Text("Склад рівня")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(viewModel.isStatsExpanded ? 90 : 0))
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(viewModel.isStatsExpanded ? "розгорнуто" : "згорнуто")

            if viewModel.isStatsExpanded {
                VStack(spacing: 10) {
                    ForEach(viewModel.platformStats, id: \.0) { type, count in
                        HStack(spacing: 10) {
                            Capsule()
                                .fill(Theme.color(for: type))
                                .frame(width: 26, height: 8)
                            Text(type.title.prefix(1).uppercased() + type.title.dropFirst())
                            Spacer()
                            Text("\(count)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                .padding([.horizontal, .bottom], 14)
                .transition(statsTransition)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .cardStyle(cornerRadius: 18)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.play()
            } label: {
                Label("Грати", systemImage: "play.fill")
            }
            .buttonStyle(.gradient)

            Button {
                viewModel.simulate()
            } label: {
                Label("Симуляція (8 с)", systemImage: "wand.and.rays")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .padding(.top, 6)
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
