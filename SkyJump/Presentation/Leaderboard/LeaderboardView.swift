import SwiftUI

/// Екран «Лідери»: глобальна таблиця нескінченного режиму з власного сервера.
/// Стани (завантаження, порожньо, помилка) показуються всередині списку,
/// тож поле ніка й навігація лишаються доступними за будь-якого стану.
struct LeaderboardView: View {
    @State private var viewModel: LeaderboardViewModel
    @FocusState private var isNicknameFocused: Bool
    @Environment(\.worldTheme) private var theme

    init(viewModel: LeaderboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                nicknameCard
                    .plainRow()
                if let text = viewModel.lastSubmissionText {
                    lastSubmissionBanner(text)
                        .plainRow()
                }
            }

            Section {
                content
            } header: {
                Text("Топ-\(LeaderboardViewModel.limit) нескінченного режиму")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .appBackground()
        .scrollDismissesKeyboard(.interactively)
        .animation(.snappy, value: viewModel.state)
        .navigationTitle("Лідери")
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) { scenarioMenu }
            #endif
        }
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Стани

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Завантажуємо таблицю…")
                .frame(maxWidth: .infinity, minHeight: 160)
                .plainRow()
        case .loaded(let entries):
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(rank: index + 1, entry: entry, isOwn: viewModel.isOwn(entry))
                    .plainRow()
            }
        case .empty:
            ContentUnavailableView("Ще ніхто не грав",
                                   systemImage: "trophy",
                                   description: Text("Зіграй нескінченний режим — і твій рахунок буде першим."))
                .plainRow()
        case .failed(let message):
            ContentUnavailableView {
                Label("Таблиця недоступна", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Спробувати ще раз") { viewModel.retry() }
                    .buttonStyle(.gradient)
                    .frame(maxWidth: 260)
            }
            .plainRow()
        }
    }

    // MARK: - Нік

    private var nicknameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Твій нік у таблиці")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                TextField("Нік", text: $viewModel.nicknameDraft)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNicknameFocused)
                    .onSubmit { viewModel.saveNickname() }
                Button("Зберегти") {
                    viewModel.saveNickname()
                    isNicknameFocused = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSaveNickname)
            }
            if let message = viewModel.nicknameMessage {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            } else {
                Text("Під цим ніком надсилається рахунок нескінченного режиму.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .cardStyle(cornerRadius: 18)
    }

    private func lastSubmissionBanner(_ text: String) -> some View {
        Label(text, systemImage: viewModel.lastSubmissionFailed ? "exclamationmark.triangle.fill" : "paperplane.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(viewModel.lastSubmissionFailed ? Color.orange : Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .cardStyle(cornerRadius: 14)
    }

    // MARK: - Режим перевірки

    #if DEBUG
    private var scenarioMenu: some View {
        Menu {
            Picker("Режим перевірки", selection: $viewModel.scenario) {
                ForEach(LeaderboardScenario.allCases) { scenario in
                    Text(scenario.title).tag(scenario)
                }
            }
        } label: {
            Label("Режим перевірки", systemImage: "ladybug")
        }
    }
    #endif
}

/// Рядок таблиці: місце, нік з емодзі теми, коли набрано, рахунок.
private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isOwn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(LeaderboardViewModel.rankLabel(rank))
                .font(rank <= 3 ? .title2 : .headline.monospacedDigit())
                .frame(minWidth: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.player)
                        .font(.headline)
                        .lineLimit(1)
                    if isOwn {
                        Text("ти")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.neonPink.opacity(0.25), in: Capsule())
                    }
                }
                HStack(spacing: 4) {
                    Text(LeaderboardViewModel.themeEmoji(entry.theme))
                    // увесь інтерфейс українською, тож і «5 хвилин тому» — незалежно від мови системи
                    // (Text бере локаль для форматування з оточення)
                    Text(entry.createdAt, format: .relative(presentation: .named))
                        .environment(\.locale, Locale(identifier: "uk_UA"))
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("\(entry.score)")
                .font(.title3.weight(.bold).monospacedDigit())
        }
        .padding(12)
        .cardStyle(cornerRadius: 18)
        .overlay {
            if isOwn {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.neonPink.opacity(0.8), lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rank) місце, \(entry.player)\(isOwn ? ", це ти" : ""), рахунок \(entry.score)")
    }
}

private extension View {
    /// Рядок списку без системного фону й розділювачів — картки малюються самі.
    func plainRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
    }
}

#Preview("Дані") {
    NavigationStack {
        LeaderboardView(viewModel: LeaderboardViewModel(provider: StubLeaderboard(scenario: .sample)))
    }
}

#Preview("Порожньо") {
    NavigationStack {
        LeaderboardView(viewModel: LeaderboardViewModel(provider: StubLeaderboard(scenario: .empty)))
    }
}

#Preview("Помилка") {
    NavigationStack {
        LeaderboardView(viewModel: LeaderboardViewModel(provider: StubLeaderboard(scenario: .offline)))
    }
}
