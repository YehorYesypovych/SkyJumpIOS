import SwiftUI

/// Результат гри поверх ігрового поля: перемога або падіння, рахунок, рекорд і дії.
struct GameResultOverlay: View {
    let outcome: GameOutcome
    let score: Int
    let bestScore: Int
    let isNewRecord: Bool
    let onRestart: () -> Void
    let onBackToLevel: () -> Void
    let onBackToList: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRecordBadgeVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    card
                        .frame(maxWidth: 420)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .task {
            guard isNewRecord else { return }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.4)) {
                isRecordBadgeVisible = true
            }
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            Image(systemName: isWin ? "flag.checkered" : "arrow.down.circle")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(isWin ? .green : .orange)

            Text(isWin ? "Перемога!" : "Падіння")
                .font(.largeTitle.bold())

            Text("Рахунок: \(score)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()

            if isRecordBadgeVisible {
                Label("Новий рекорд!", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.green, in: Capsule())
                    .transition(recordTransition)
            }

            Text("Рекорд рівня: \(bestScore)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Button {
                    onRestart()
                } label: {
                    Label("Ще раз", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onBackToLevel()
                } label: {
                    Text("До рівня").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onBackToList()
                } label: {
                    Text("До списку").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var isWin: Bool { outcome == .won }

    /// Бейдж «вистрибує» з пружиною; з Reduce Motion — лише плавна поява.
    private var recordTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity)
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
