import Foundation
import Testing
@testable import SkyJump

@MainActor
struct LevelLibraryTests {

    @Test func addUpdateDelete() {
        let library = LevelLibrary(levels: [])
        var level = LevelPreset.makeNew()
        level.name = "Тест"

        library.add(level)
        #expect(library.levels.count == 1)

        level.name = "Нова назва"
        library.update(level)
        #expect(library.level(id: level.id)?.name == "Нова назва")
        #expect(library.levels.count == 1)

        library.delete(id: level.id)
        #expect(library.levels.isEmpty)
        #expect(library.level(id: level.id) == nil)
    }

    @Test func recordResultKeepsBestScore() {
        let library = LevelLibrary()
        let id = library.levels[0].id

        #expect(library.recordResult(levelID: id, score: 500))
        #expect(!library.recordResult(levelID: id, score: 300))
        #expect(library.recordResult(levelID: id, score: 800))

        let level = library.level(id: id)
        #expect(level?.bestScore == 800)
        #expect(level?.playsCount == 3)
    }

    @Test func recordResultForUnknownLevelIsIgnored() {
        let library = LevelLibrary()
        #expect(!library.recordResult(levelID: UUID(), score: 100))
        #expect(library.levels.allSatisfy { $0.playsCount == 0 })
    }

    @Test func samePresetGivesSameLevel() {
        let preset = LevelPreset.samples[1]
        let first = PresetLevelProvider(preset: preset).makeLevel()
        let second = PresetLevelProvider(preset: preset).makeLevel()

        #expect(first.count == preset.platformCount)
        #expect(first.map(\.type) == second.map(\.type))
        #expect(first.map(\.position.x) == second.map(\.position.x))
    }

    @Test func presetUsesOnlyAllowedPlatformTypes() {
        let preset = LevelPreset.samples[2]   // складний рівень: без пружин
        let types = Set(PresetLevelProvider(preset: preset).makeLevel().map(\.type))

        #expect(types.isSubset(of: Set(preset.difficulty.allowedTypes)))
        #expect(!types.contains(.spring))
    }
}
