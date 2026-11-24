import SwiftUI

/// Обкладинка станції: логотип з каталогу або градієнтна плитка з 📻, якщо логотипу немає.
struct StationArtwork: View {
    let station: RadioStation?
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Theme.sunset)
            Text("📻")
                .font(.system(size: size * 0.5))
            if let url = station?.faviconURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// «Еквалайзер», що підстрибує, поки станція грає. З Reduce Motion — нерухомий.
struct EqualizerBars: View {
    var isAnimating: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !isAnimating || reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    let phase = sin(time * (5 + Double(index) * 1.7) + Double(index))
                    Capsule()
                        .fill(Theme.neonMint)
                        .frame(width: 3, height: isAnimating && !reduceMotion ? 6 + 8 * (phase + 1) / 2 : 8)
                }
            }
            .frame(width: 20, height: 16, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// Міні-програвач унизу меню: поточна станція і кнопки, тап — відкрити екран «Радіо».
struct MiniPlayerBar: View {
    let player: RadioPlayer
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    StationArtwork(station: player.current, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.current?.name ?? "Радіо SkyJump")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if player.current != nil {
                if player.state == .playing {
                    EqualizerBars(isAnimating: true)
                }
                Button {
                    player.toggle()
                } label: {
                    Image(systemName: player.isActive ? "stop.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel(player.isActive ? "Зупинити радіо" : "Увімкнути радіо")

                if player.queue.count > 1 {
                    Button {
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Наступна станція")
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.cardStroke, lineWidth: 1))
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    private var statusText: String {
        guard let current = player.current else { return "Обери станцію під настрій 🌴" }
        switch player.state {
        case .playing: return "Грає · \(current.genre)"
        case .loading: return "Підключення…"
        case .failed: return "Не вдалося підключитися"
        case .idle: return "Натисни ▶︎, щоб увімкнути"
        }
    }
}
