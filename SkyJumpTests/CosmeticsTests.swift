import Foundation
import Testing
@testable import SkyJump

@MainActor
struct CosmeticsTests {

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "tests.cosmetics.\(UUID().uuidString)")!
    }

    @Test func defaultsAreNeonBeach() {
        let settings = CosmeticsSettings(defaults: makeDefaults())
        #expect(settings.theme == .neonBeach)
        #expect(settings.skin == .shades)
        #expect(settings.trail == .neon)
    }

    @Test func choiceIsRemembered() {
        let defaults = makeDefaults()
        let settings = CosmeticsSettings(defaults: defaults)
        settings.theme = .olympus
        settings.skin = .laurel
        settings.trail = .stars

        let restored = CosmeticsSettings(defaults: defaults)
        #expect(restored.theme == .olympus)
        #expect(restored.skin == .laurel)
        #expect(restored.trail == .stars)
    }

    @Test func stagesFollowHeight() {
        let olympus = WorldTheme.olympus
        #expect(olympus.stage(atHeight: 0).title == "Земля")
        #expect(olympus.stage(atHeight: 2_000).title == "Хмари")
        #expect(olympus.stage(atHeight: 10_000).title == "Космос")
        #expect(WorldTheme.allCases.allSatisfy { $0.stages.first?.startHeight == 0 })
    }
}
