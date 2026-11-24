import SwiftUI

/// Справжня гра: поле малюється на Canvas щокадру, керування — утримання лівої чи правої половини екрана.
struct GameplayView: View {
    @State private var viewModel: GameplayViewModel
    /// Радіо застосунку: на паузі притишується, на екрані паузи можна перемкнути станцію.
    let radio: RadioPlayer
    /// Обрані тема, скін і слід.
    let cosmetics: CosmeticsSettings
    @State private var clock = FrameClock()
    @State private var stageTitle: String?          // назва етапу, яку зараз показуємо
    @State private var lastStageTitle = ""          // останній оголошений етап
    @State private var hasTouched = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: GameplayViewModel, radio: RadioPlayer, cosmetics: CosmeticsSettings) {
        _viewModel = State(initialValue: viewModel)
        self.radio = radio
        self.cosmetics = cosmetics
    }

    private var appearance: GameAppearance {
        GameAppearance(theme: cosmetics.theme, skin: cosmetics.skin, trail: cosmetics.trail)
    }

    /// Колір HUD: білий на темних темах, темний на світлій «Класиці».
    private var hudColor: Color {
        cosmetics.theme.palette.isDark ? .white : Color(red: 0.12, green: 0.12, blue: 0.18)
    }

    var body: some View {
        Group {
            if !viewModel.hasStarted && viewModel.isUnavailable {
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
            radio.setDucked(false)
        }
        .onChange(of: viewModel.isPaused) { _, isPaused in
            radio.setDucked(isPaused)
        }
        .onChange(of: cosmetics.theme.stage(atHeight: Double(viewModel.hud.score)).title) { _, title in
            announceStage(title)
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
                // окремий вигляд: лише він читає кадр і перемальовується щокадру
                GameCanvas(viewModel: viewModel, clock: clock, appearance: appearance)
                    .ignoresSafeArea()
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
                                      score: viewModel.hud.score,
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

    /// Показує назву нового етапу світу на 2 секунди — відчуття, що проходиш шлях угору.
    private func announceStage(_ title: String) {
        guard viewModel.hasStarted, title != lastStageTitle else { return }
        lastStageTitle = title
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4)) {
            stageTitle = title
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                if stageTitle == title {
                    stageTitle = nil
                }
            }
        }
    }

    /// Утримання лівої половини — рух уліво, правої — управо, відпускання — зупинка.
    private func controlGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // стан змінюємо лише раз: onChanged приходить на кожен рух пальця
                if !hasTouched {
                    hasTouched = true
                }
                viewModel.setInput(value.location.x < width / 2 ? -1 : 1)
            }
            .onEnded { _ in
                viewModel.setInput(0)
            }
    }

    // MARK: - HUD

    private var hud: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Text("\(viewModel.hud.score)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(viewModel.hud.score)))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer(minLength: 8)

                Label("\(viewModel.bestScore)", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityLabel("Рекорд рівня \(viewModel.bestScore)")
            }

            ProgressBar(value: viewModel.hud.progress)
                .accessibilityLabel("Прогрес до вершини")

            if radio.state == .playing, let station = radio.current {
                HStack(spacing: 6) {
                    Text("📻")
                    Text(station.name)
                        .lineLimit(1)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Радіо: \(station.name)")
            }

            if viewModel.hud.jetpackLeft > 0 {
                HStack(spacing: 8) {
                    Text("🚀")
                    ProgressBar(value: viewModel.hud.jetpackLeft, fill: Theme.neonMint)
                        .frame(width: 90)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.scale.combined(with: .opacity))
            }

            if let stageTitle {
                Sticker(text: stageTitle, emoji: cosmetics.theme.emoji,
                        color: cosmetics.theme.palette.accent, angle: 3)
                    .padding(.top, 16)
                    .transition(.scale.combined(with: .opacity))
            }

            if !hasTouched && viewModel.outcome == .playing && !viewModel.isPaused {
                Sticker(text: "тримай ліво / право", emoji: "👆", color: Theme.electricBlue, angle: -3)
                    .padding(.top, 24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundStyle(hudColor)
        .padding(.horizontal)
        .padding(.top, 4)
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: viewModel.hud.jetpackLeft > 0)
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: hasTouched)
        .onAppear {
            lastStageTitle = cosmetics.theme.stages[0].title
        }
    }

    private var pauseOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Sticker(text: "пауза", emoji: "☕️", color: Theme.dusk, angle: -4)
                    .scaleEffect(1.3)
                Button {
                    clock.reset()
                    viewModel.resume()
                } label: {
                    Label("Продовжити", systemImage: "play.fill")
                }
                .buttonStyle(.gradient)
                .frame(maxWidth: 280)

                Button("До рівня") {
                    viewModel.backToLevel()
                }
                .font(.headline)

                if radio.current != nil {
                    radioControls
                        .padding(.top, 12)
                }
            }
            .padding()
        }
    }
}

extension GameplayView {
    /// Радіо на екрані паузи: поточна станція, пуск/стоп і наступна станція.
    private var radioControls: some View {
        VStack(spacing: 10) {
            radioStationRow
            RadioVolumeSlider(player: radio)
        }
        .padding(12)
        .frame(maxWidth: 320)
        .cardStyle(cornerRadius: 20)
    }

    private var radioStationRow: some View {
        HStack(spacing: 12) {
            StationArtwork(station: radio.current, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(radio.current?.name ?? "")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(radio.isActive ? "Радіо грає" : "Радіо вимкнено")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                radio.toggle()
            } label: {
                Image(systemName: radio.isActive ? "stop.fill" : "play.fill")
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel(radio.isActive ? "Зупинити радіо" : "Увімкнути радіо")
            if radio.queue.count > 1 {
                Button {
                    radio.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Наступна станція")
            }
        }
    }
}

/// Тонка смуга прогресу з градієнтом.
private struct ProgressBar: View {
    let value: Double
    var fill: Color?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25))
                Capsule()
                    .fill(fill.map { AnyShapeStyle($0) } ?? AnyShapeStyle(Theme.playButton))
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Поле гри

/// Поле гри, що перемальовується щокадру. Винесене окремо, щоб 60 разів на секунду
/// оновлювався лише Canvas, а не HUD, кнопки й оверлеї.
private struct GameCanvas: View {
    let viewModel: GameplayViewModel
    let clock: FrameClock
    let appearance: GameAppearance

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !viewModel.isPlaying)) { timeline in
            // opaque: фон повністю зафарбовує поле, тож системі не треба змішувати його з тим, що під ним
            Canvas(opaque: true) { context, size in
                GameRenderer.draw(viewModel.frame, appearance: appearance, in: &context, size: size)
            }
            .onChange(of: timeline.date) { _, date in
                if let deltaTime = clock.advance(to: date) {
                    viewModel.tick(deltaTime: deltaTime)
                }
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
/// Як виглядає гра: тема світу, скін і слід.
struct GameAppearance: Equatable {
    var theme: WorldTheme
    var skin: PlayerSkin
    var trail: TrailStyle
}

private enum GameRenderer {
    static let platformHeight = 14.0

    static func draw(_ frame: GameFrame, appearance: GameAppearance,
                     in context: inout GraphicsContext, size: CGSize) {
        let scale = size.width / GameFrame.worldWidth
        let palette = appearance.theme.palette

        func screenY(_ worldY: Double) -> CGFloat {
            size.height - CGFloat(worldY - frame.cameraBottom) * scale
        }

        WorldRenderer.drawBackground(theme: appearance.theme, in: &context, size: size,
                                     cameraBottom: frame.cameraBottom, scale: scale)

        for platform in frame.platforms {
            let rect = CGRect(x: platform.x * scale,
                              y: screenY(platform.y),
                              width: platform.width * scale,
                              height: platformHeight * scale)
            guard rect.maxY >= -40, rect.minY <= size.height else { continue }
            drawPlatform(platform, rect: rect, scale: scale, palette: palette, in: &context)
        }

        if !frame.pickups.isEmpty {
            // емодзі розкладається на гліфи один раз за кадр, а не для кожного бонуса
            let rocket = context.resolve(Text("🚀").font(.system(size: 24 * scale)))
            for pickup in frame.pickups {
                let bottom = CGPoint(x: pickup.x * scale, y: screenY(pickup.y))
                guard bottom.y > -40, bottom.y < size.height + 40 else { continue }
                drawJetpackPickup(rocket, at: bottom, scale: scale, in: &context)
            }
        }

        // слід за персонажем
        let trailPoints = frame.trail.map { point in CGPoint(x: point.x * scale, y: screenY(point.y)) }
        PlayerRenderer.drawTrail(appearance.trail, points: trailPoints, width: frame.playerWidth * scale,
                                 color: palette.accent, in: &context)

        // персонаж біля краю видно з обох боків — так само, як він переходить через край світу
        let playerX: CGFloat = frame.playerX * scale
        let worldWidth: CGFloat = GameFrame.worldWidth * scale
        let halfWidth: CGFloat = frame.playerWidth * scale / 2
        let flicker: CGFloat = CGFloat(abs(frame.playerY).truncatingRemainder(dividingBy: 12)) / 12
        for offset in [-worldWidth, 0, worldWidth] {
            let centerX = playerX + offset
            guard centerX + halfWidth > 0, centerX - halfWidth < size.width else { continue }
            let pose = PlayerRenderer.Pose(centerX: centerX, feetY: screenY(frame.playerY),
                                           width: halfWidth * 2, isFalling: frame.isFalling,
                                           hasJetpack: frame.jetpackLeft > 0, flicker: flicker)
            PlayerRenderer.draw(skin: appearance.skin, pose: pose, in: &context)
        }
    }

    // MARK: Платформи

    private static func drawPlatform(_ platform: GameFrame.PlatformSprite, rect: CGRect, scale: CGFloat,
                                     palette: ThemePalette, in context: inout GraphicsContext) {
        let color = palette.color(for: platform.type)
        let opacity = platform.isBroken ? 0.25 : 1
        // тінь — просто зсунута темна смужка: без розмиття, яке дорого рахувати щокадру
        let shadow = rect.offsetBy(dx: 0, dy: 3 * scale)
        context.fill(Path(roundedRect: shadow, cornerRadius: shadow.height / 2),
                     with: .color(.black.opacity(0.22 * opacity)))
        let shape = Path(roundedRect: rect, cornerRadius: rect.height / 2)
        context.fill(shape, with: .color(color.opacity(opacity)))
        // тонкий темний контур: платформу видно і на світлому заході сонця
        context.stroke(shape, with: .color(Theme.night.opacity(0.35 * opacity)), lineWidth: 1.2 * scale)

        // світла смужка зверху — об'єм без зайвих деталей
        let highlight = CGRect(x: rect.minX + rect.height / 2, y: rect.minY + 2 * scale,
                               width: max(rect.width - rect.height, 0), height: 2.5 * scale)
        context.fill(Path(roundedRect: highlight, cornerRadius: 1.25 * scale),
                     with: .color(.white.opacity(0.55 * opacity)))

        guard !platform.isBroken else { return }

        switch platform.type {
        case .spring:
            // пружина-зигзаг і рожева «кнопка» зверху
            var coil = Path()
            let baseY = rect.minY
            let left = rect.midX - 7 * scale
            coil.move(to: CGPoint(x: left, y: baseY))
            for step in 1...4 {
                coil.addLine(to: CGPoint(x: step.isMultiple(of: 2) ? left : left + 14 * scale,
                                         y: baseY - CGFloat(step) * 3 * scale))
            }
            context.stroke(coil, with: .color(.white), lineWidth: 2 * scale)
            let cap = CGRect(x: rect.midX - 9 * scale, y: baseY - 15 * scale, width: 18 * scale, height: 4 * scale)
            context.fill(Path(roundedRect: cap, cornerRadius: 2 * scale), with: .color(palette.accent))
        case .breakable:
            // ціла — одна тонка тріщина; після першого стрибку — глибокі тріщини на всю платформу
            var crack = Path()
            crack.move(to: CGPoint(x: rect.midX - 8 * scale, y: rect.minY))
            crack.addLine(to: CGPoint(x: rect.midX - 1 * scale, y: rect.midY))
            crack.addLine(to: CGPoint(x: rect.midX + 6 * scale, y: rect.maxY))
            if platform.isCracked {
                for offset in [-0.3, 0.3] {
                    let x = rect.midX + rect.width * CGFloat(offset)
                    crack.move(to: CGPoint(x: x - 4 * scale, y: rect.minY))
                    crack.addLine(to: CGPoint(x: x + 3 * scale, y: rect.midY))
                    crack.addLine(to: CGPoint(x: x - 2 * scale, y: rect.maxY))
                }
            }
            context.stroke(crack, with: .color(.black.opacity(platform.isCracked ? 0.6 : 0.35)),
                           lineWidth: (platform.isCracked ? 2 : 1.5) * scale)
        case .moving:
            for direction in [-1.0, 1.0] {
                var chevron = Path()
                let x = rect.midX + CGFloat(direction) * rect.width * 0.32
                let size = 3.5 * scale
                chevron.move(to: CGPoint(x: x - CGFloat(direction) * size, y: rect.midY - size))
                chevron.addLine(to: CGPoint(x: x, y: rect.midY))
                chevron.addLine(to: CGPoint(x: x - CGFloat(direction) * size, y: rect.midY + size))
                context.stroke(chevron, with: .color(.white.opacity(0.8)),
                               style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round, lineJoin: .round))
            }
        case .normal:
            break
        }
    }

    // MARK: Джетпак

    private static func drawJetpackPickup(_ rocket: GraphicsContext.ResolvedText, at bottom: CGPoint,
                                          scale: CGFloat, in context: inout GraphicsContext) {
        let glow = CGRect(x: bottom.x - 20 * scale, y: bottom.y - 40 * scale, width: 40 * scale, height: 40 * scale)
        context.fill(Path(ellipseIn: glow), with: .color(Theme.neonMint.opacity(0.35)))
        context.draw(rocket, at: CGPoint(x: bottom.x, y: bottom.y - 20 * scale))
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let library = LevelLibrary()
    NavigationStack {
        GameplayView(viewModel: GameplayViewModel(levelID: library.levels[0].id,
                                                  library: library,
                                                  scoreStore: InMemoryScoreStore(),
                                                  navigator: router),
                     radio: .preview(),
                     cosmetics: CosmeticsSettings(defaults: UserDefaults(suiteName: "preview.cosmetics") ?? .standard))
    }
}
