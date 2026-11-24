import SwiftUI

/// Меню персоналізації: тема світу (меню, рівні й фон гри), скін персонажа і слід за ним.
struct CustomizeView: View {
    @Bindable var settings: CosmeticsSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CosmeticsPreview(theme: settings.theme, skin: settings.skin, trail: settings.trail)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .accessibilityLabel("Попередній перегляд: \(settings.theme.title), \(settings.skin.title), \(settings.trail.title)")

                section("Тема") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(WorldTheme.allCases) { theme in
                                ThemeCard(theme: theme, isSelected: settings.theme == theme) {
                                    select { settings.theme = theme }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Text("Тема змінює меню, рівні й те, яким шляхом ти піднімаєшся: \(stagesText).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                section("Персонаж") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                        ForEach(PlayerSkin.allCases) { skin in
                            SkinCard(skin: skin, isSelected: settings.skin == skin) {
                                select { settings.skin = skin }
                            }
                        }
                    }
                }

                section("Слід") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(TrailStyle.allCases) { trail in
                            OptionChip(title: trail.title, emoji: trail.emoji, isSelected: settings.trail == trail) {
                                select { settings.trail = trail }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Стиль")
    }

    private var stagesText: String {
        settings.theme.stages.map(\.title).joined(separator: " → ")
    }

    private func select(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .snappy) {
            change()
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.bold))
            content()
        }
    }
}

// MARK: - Попередній перегляд

/// Маленька сцена: фон теми, платформа, персонаж у скіні та слід за ним.
struct CosmeticsPreview: View {
    let theme: WorldTheme
    let skin: PlayerSkin
    let trail: TrailStyle

    var body: some View {
        Canvas { context, size in
            let scale: CGFloat = size.width / CGFloat(GameConfig.worldWidth)
            WorldRenderer.drawBackground(theme: theme, in: &context, size: size,
                                         cameraBottom: -GameplayViewModel.cameraOffset, scale: scale)

            let palette = theme.palette
            let platform = CGRect(x: size.width * 0.5 - 40 * scale, y: size.height * 0.82,
                                  width: 80 * scale, height: 14 * scale)
            context.fill(Path(roundedRect: platform, cornerRadius: platform.height / 2),
                         with: .color(palette.normalPlatform))

            // слід по дузі стрибка
            let width: CGFloat = CGFloat(GameConfig.playerWidth) * scale * 1.4
            let points: [CGPoint] = (0..<16).map { index in
                let t: CGFloat = CGFloat(index) / 15
                let x: CGFloat = size.width * (0.18 + 0.3 * t)
                let y: CGFloat = size.height * (0.75 - 0.45 * sin(t * .pi * 0.9))
                return CGPoint(x: x, y: y)
            }
            PlayerRenderer.drawTrail(trail, points: points, width: width, color: palette.accent, in: &context)

            let pose = PlayerRenderer.Pose(centerX: size.width * 0.52, feetY: size.height * 0.36,
                                           width: width, isFalling: false, hasJetpack: false, flicker: 0)
            PlayerRenderer.draw(skin: skin, pose: pose, in: &context)
        }
    }
}

// MARK: - Картки вибору

private struct ThemeCard: View {
    let theme: WorldTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    LinearGradient(colors: theme.palette.background, startPoint: .top, endPoint: .bottom)
                    Text(theme.emoji)
                        .font(.system(size: 34))
                }
                .frame(width: 110, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? theme.palette.accent : .clear, lineWidth: 3)
                }
                Text(theme.title)
                    .font(.footnote.weight(isSelected ? .bold : .medium))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SkinCard: View {
    let skin: PlayerSkin
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.worldTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Canvas { context, size in
                    let pose = PlayerRenderer.Pose(centerX: size.width / 2, feetY: size.height * 0.9,
                                                   width: size.width * 0.42, isFalling: false,
                                                   hasJetpack: false, flicker: 0)
                    PlayerRenderer.draw(skin: skin, pose: pose, in: &context)
                }
                .frame(height: 72)
                Text(skin.title)
                    .font(.footnote.weight(isSelected ? .bold : .medium))
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .cardStyle(cornerRadius: 18)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? theme.palette.accent : .clear, lineWidth: 2.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OptionChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.worldTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.palette.accent)
                }
            }
            .padding(12)
            .cardStyle(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        CustomizeView(settings: CosmeticsSettings(defaults: UserDefaults(suiteName: "preview.cosmetics") ?? .standard))
    }
}
