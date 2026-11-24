import SwiftUI

/// Екран «Радіо»: станції synthwave / retrowave / 80s з відкритого каталогу, фільтр за жанром.
struct RadioView: View {
    @State private var viewModel: RadioViewModel
    @Environment(\.worldTheme) private var theme

    init(viewModel: RadioViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.visibleStations) { station in
                    Button {
                        viewModel.select(station)
                    } label: {
                        StationRow(station: station,
                                   isCurrent: viewModel.isCurrent(station),
                                   state: viewModel.player.state)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                }
            } header: {
                VStack(spacing: 8) {
                    RadioVolumeSlider(player: viewModel.player)
                        .padding(.horizontal, 4)
                    genreChips
                }
                .textCase(nil)
            }
        }
        .listStyle(.plain)
        .appBackground()
        .overlay { stateOverlay }
        .navigationTitle("Радіо")
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if viewModel.player.current != nil {
                MiniPlayerBar(player: viewModel.player, onOpen: {})
            }
        }
    }

    private var genreChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Усі", genre: nil)
                ForEach(RadioGenre.allCases) { genre in
                    chip(title: genre.title, genre: genre)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func chip(title: String, genre: RadioGenre?) -> some View {
        let isSelected = viewModel.selectedGenre == genre
        return Button {
            withAnimation(.snappy) {
                viewModel.selectedGenre = genre
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    if isSelected {
                        Capsule().fill(theme.palette.buttonGradient)
                    } else {
                        Capsule().fill(theme.palette.card)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch viewModel.loadState {
        case .loading where viewModel.stations.isEmpty:
            ProgressView("Шукаємо хвилі…")
        case .failed(let message) where viewModel.stations.isEmpty:
            ContentUnavailableView {
                Label("Радіо мовчить", systemImage: "antenna.radiowaves.left.and.right.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Спробувати ще раз") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.gradient)
                .frame(maxWidth: 260)
            }
        case .loaded where viewModel.visibleStations.isEmpty:
            ContentUnavailableView("У цьому жанрі зараз нічого",
                                   systemImage: "music.note",
                                   description: Text("Обери інший жанр."))
        default:
            EmptyView()
        }
    }
}

/// Рядок станції: обкладинка, назва, країна й жанр; праворуч — стан відтворення.
private struct StationRow: View {
    let station: RadioStation
    let isCurrent: Bool
    let state: StreamState

    var body: some View {
        HStack(spacing: 12) {
            StationArtwork(station: station)

            VStack(alignment: .leading, spacing: 3) {
                Text(station.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Group {
                if isCurrent && state == .playing {
                    EqualizerBars(isAnimating: true)
                } else if isCurrent && state == .loading {
                    ProgressView()
                } else if isCurrent && state == .failed {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.sunsetOrange)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
            }
            .frame(width: 28)
        }
        .padding(10)
        .cardStyle(cornerRadius: 18)
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.neonPink.opacity(0.8), lineWidth: 1.5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(isCurrent && state != .idle ? "Зупинити" : "Увімкнути")
    }

    private var subtitle: String {
        var parts: [String] = []
        let place = [station.flag, station.country].filter { !$0.isEmpty }.joined(separator: " ")
        if !place.isEmpty { parts.append(place) }
        parts.append(station.genre)
        if station.bitrate > 0 { parts.append("\(station.bitrate) kbps") }
        return parts.joined(separator: " · ")
    }
}
