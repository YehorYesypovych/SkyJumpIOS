import SwiftUI

struct ContentView: View {
    @State private var logLines: [String] = []
    @State private var summary: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Button("Запустити демо-сценарій") {
                    runDemo()
                }
                .buttonStyle(.borderedProminent)

                if let summary {
                    Text(summary)
                        .font(.callout)
                }

                List(Array(logLines.enumerated()), id: \.offset) { item in
                    Text(item.element)
                        .font(.system(.footnote, design: .monospaced))
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("SkyJump")
        }
    }

    private func runDemo() {
        let session = GameSession(playerName: "Doodler",
                                  platforms: LevelFactory.makeDemoLevel())
        session.run(duration: 8)

        logLines = session.log
        summary = session.summary()

        // Дублюємо результат у консоль Xcode
        session.log.forEach { print($0) }
        print(session.summary())
    }
}

#Preview {
    ContentView()
}

