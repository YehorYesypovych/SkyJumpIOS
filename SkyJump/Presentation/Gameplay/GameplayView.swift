import SwiftUI

/// Справжня гра: поле малюється на Canvas щокадру, керування — утримання лівої чи правої половини екрана.
struct GameplayView: View {
    @State private var viewModel: GameplayViewModel
    @State private var clock = FrameClock()
    @State private var hasTouched = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: GameplayViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if !viewModel.hasStarted && viewModel.level == nil {
                ContentUnavailableView {
                    Label("Рівень не знайдено", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("Можливо, його видалили.")
                } actions: {
                    Button("До списку") { viewModel.backToList() }
                }
            } else {
                gameField
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.hasStarted && viewModel.outcome == .playing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isPaused ? "Продовжити" : "Пауза",
                           systemImage: viewModel.isPaused ? "play.fill" : "pause.fill") {
                        clock.reset()
                        viewModel.togglePause()
                    }
                }
            }
        }
        .onAppear {
            if !viewModel.hasStarted {
                viewModel.start()
            }
        }
        .onDisappear {
            viewModel.pause()
        }
        .onChange(of: scenePhase) { _, phase in
            // згорнули застосунок або прийшов дзвінок — гра стає на паузу
            if phase != .active {
                viewModel.pause()
            }
        }
    }

    // MARK: - Ігрове поле

    private var gameField: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                TimelineView(.animation(minimumInterval: nil, paused: !viewModel.isPlaying)) { timeline in
                    Canvas { context, size in
                        GameRenderer.draw(viewModel.frame, in: &context, size: size)
                    }
                    .onChange(of: timeline.date) { _, date in
                        if let deltaTime = clock.advance(to: date) {
                            viewModel.tick(deltaTime: deltaTime)
                        }
                    }
                }
                .background(GameRenderer.sky)
                .contentShape(Rectangle())
                .gesture(controlGesture(width: proxy.size.width))

                hud
                    .allowsHitTesting(false)

                if viewModel.isPaused {
                    pauseOverlay
                        .transition(.opacity)
                }

                if viewModel.outcome != .playing {
                    GameResultOverlay(outcome: viewModel.outcome,
                                      score: viewModel.frame.score,
                                      bestScore: viewModel.bestScore,
                                      isNewRecord: viewModel.isNewRecord,
                                      onRestart: {
                                          clock.reset()
                                          viewModel.restart()
                                      },
                                      onBackToLevel: { viewModel.backToLevel() },
                                      onBackToList: { viewModel.backToList() })
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.outcome)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.isPaused)
        }
    }

    /// Утримання лівої половини — рух уліво, правої — управо, відпускання — зупинка.
    private func controlGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                hasTouched = true
                viewModel.setInput(value.location.x < width / 2 ? -1 : 1)
            }
            .onEnded { _ in
                viewModel.setInput(0)
            }
    }

    private var hud: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.frame.score)")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .monospacedDigit()
                Spacer()
                Text("Рекорд: \(viewModel.bestScore)")
                    .font(.subheadline.weight(.semibold))
            }
            ProgressView(value: viewModel.frame.progress)
                .tint(.white)
                .accessibilityLabel("Прогрес до вершини")

            if !hasTouched && viewModel.outcome == .playing {
                Text("Утримуйте ліву або праву половину екрана, щоб рухатися")
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 2)
        .padding()
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Пауза")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Button {
                    clock.reset()
                    viewModel.resume()
                } label: {
                    Label("Продовжити", systemImage: "play.fill")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("До рівня") {
                    viewModel.backToLevel()
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
    }
}

// MARK: - Час кадру

/// Рахує час між кадрами TimelineView. Після паузи скидається, щоб не було великого стрибка.
private final class FrameClock {
    private var lastDate: Date?

    func advance(to date: Date) -> Double? {
        defer { lastDate = date }
        guard let lastDate else { return nil }
        return date.timeIntervalSince(lastDate)
    }

    func reset() {
        lastDate = nil
    }
}

// MARK: - Малювання

/// Малює кадр гри: світ (y угору) перетворюється в координати екрана (y униз) з урахуванням камери.
private enum GameRenderer {
    static let platformHeight = 14.0

    static let sky = LinearGradient(colors: [Color(red: 0.36, green: 0.67, blue: 0.98),
                                             Color(red: 0.80, green: 0.92, blue: 1.0)],
                                    startPoint: .top,
                                    endPoint: .bottom)

    static func draw(_ frame: GameFrame, in context: inout GraphicsContext, size: CGSize) {
        let scale = size.width / GameFrame.worldWidth

        func screenY(_ worldY: Double) -> CGFloat {
            size.height - CGFloat(worldY - frame.cameraBottom) * scale
        }

        for platform in frame.platforms {
            let rect = CGRect(x: platform.x * scale,
                              y: screenY(platform.y),
                              width: platform.width * scale,
                              height: platformHeight * scale)
            guard rect.maxY >= 0, rect.minY <= size.height else { continue }

            let opacity = platform.isBroken ? 0.3 : 1
            context.fill(Path(roundedRect: rect, cornerRadius: rect.height / 2),
                         with: .color(color(for: platform.type).opacity(opacity)))

            if platform.type == .spring && !platform.isBroken {
                let spring = CGRect(x: rect.midX - 9 * scale,
                                    y: rect.minY - 10 * scale,
                                    width: 18 * scale,
                                    height: 10 * scale)
                context.fill(Path(roundedRect: spring, cornerRadius: 3 * scale), with: .color(.yellow))
            }

            if platform.type == .breakable && !platform.isBroken {
                var crack = Path()
                crack.move(to: CGPoint(x: rect.midX - 6 * scale, y: rect.minY))
                crack.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
                crack.addLine(to: CGPoint(x: rect.midX + 5 * scale, y: rect.maxY))
                context.stroke(crack, with: .color(.black.opacity(0.4)), lineWidth: 1.5)
            }
        }

        drawPlayer(frame, in: &context, scale: scale, feetY: screenY(frame.playerY))
    }

    private static func drawPlayer(_ frame: GameFrame, in context: inout GraphicsContext,
                                   scale: CGFloat, feetY: CGFloat) {
        let width = frame.playerWidth * scale
        let height = width * 1.15
        let body = CGRect(x: frame.playerX * scale - width / 2, y: feetY - height,
                          width: width, height: height)
        context.fill(Path(roundedRect: body, cornerRadius: width * 0.4), with: .color(.orange))

        // очі дивляться вниз, коли персонаж падає
        let eyeSize = width * 0.22
        let eyeY = body.minY + height * 0.3
        for offset in [-width * 0.18, width * 0.18] {
            let eye = CGRect(x: body.midX + offset - eyeSize / 2, y: eyeY,
                             width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: eye), with: .color(.white))
            let pupilShift = (frame.isFalling ? 1 : -1) * eyeSize * 0.18
            let pupil = eye.insetBy(dx: eyeSize * 0.3, dy: eyeSize * 0.3).offsetBy(dx: 0, dy: pupilShift)
            context.fill(Path(ellipseIn: pupil), with: .color(.black))
        }
    }

    private static func color(for type: PlatformType) -> Color {
        switch type {
        case .normal: return .green
        case .moving: return .blue
        case .breakable: return .brown
        case .spring: return .mint
        }
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let library = LevelLibrary()
    NavigationStack {
        GameplayView(viewModel: GameplayViewModel(levelID: library.levels[0].id,
                                                  library: library,
                                                  scoreStore: InMemoryScoreStore(),
                                                  navigator: router))
    }
}
