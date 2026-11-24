import SwiftUI

/// Результат гри поверх ігрового поля: перемога або падіння, рахунок, рекорд, стікери і дії.
struct GameResultOverlay: View {
    let outcome: GameOutcome
    let score: Int
    let bestScore: Int
    let isNewRecord: Bool
    let onRestart: () -> Void
    let onBackToLevel: () -> Void
    let onBackToList: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var areStickersVisible = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    card
                        .frame(maxWidth: 400)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.45)) {
                areStickersVisible = true
            }
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            Text(isWin ? "Перемога" : "Падіння")
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(.secondary)

            Text("\(score)")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.sunsetOrange)
                Text("Рекорд рівня: \(bestScore)")
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Button {
                    onRestart()
                } label: {
                    Label("Ще раз", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.gradient)

                HStack(spacing: 12) {
                    Button {
                        onBackToLevel()
                    } label: {
                        Text("До рівня").frame(maxWidth: .infinity)
                    }
                    Button {
                        onBackToList()
                    } label: {
                        Text("До списку").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .buttonBorderShape(.capsule)
            }
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(alignment: .topLeading) {
            if areStickersVisible {
                let item = StickerSet.item(for: outcome, score: score)
                Sticker(text: item.text, emoji: item.emoji, color: item.color, angle: -9)
                    .offset(x: -10, y: -16)
                    .transition(stickerTransition)
            }
        }
        .overlay(alignment: .topTrailing) {
            if areStickersVisible && isNewRecord {
                Sticker(text: StickerSet.newRecord.text, emoji: StickerSet.newRecord.emoji,
                        color: StickerSet.newRecord.color, angle: 8)
                    .offset(x: 10, y: -14)
                    .transition(stickerTransition)
            }
        }
    }

    private var isWin: Bool { outcome == .won }

    /// Стікери «наклеюються» з пружиною; з Reduce Motion — лише плавна поява.
    private var stickerTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.3).combined(with: .opacity)
    }
}

#Preview("Перемога з рекордом") {
    GameResultOverlay(outcome: .won, score: 2140, bestScore: 2140, isNewRecord: true,
                      onRestart: {}, onBackToLevel: {}, onBackToList: {})
}

#Preview("Падіння") {
    GameResultOverlay(outcome: .lost, score: 830, bestScore: 2140, isNewRecord: false,
                      onRestart: {}, onBackToLevel: {}, onBackToList: {})
}
