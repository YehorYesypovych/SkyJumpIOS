import Foundation
import Observation

/// Обрані тема, скін і слід. Одні на весь застосунок, зберігаються в UserDefaults.
@Observable
final class CosmeticsSettings {
    var theme: WorldTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    var skin: PlayerSkin {
        didSet { defaults.set(skin.rawValue, forKey: Keys.skin) }
    }
    var trail: TrailStyle {
        didSet { defaults.set(trail.rawValue, forKey: Keys.trail) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let theme = "cosmetics.theme"
        static let skin = "cosmetics.skin"
        static let trail = "cosmetics.trail"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = defaults.string(forKey: Keys.theme).flatMap(WorldTheme.init(rawValue:)) ?? .neonBeach
        skin = defaults.string(forKey: Keys.skin).flatMap(PlayerSkin.init(rawValue:)) ?? .shades
        trail = defaults.string(forKey: Keys.trail).flatMap(TrailStyle.init(rawValue:)) ?? .neon
    }
}
