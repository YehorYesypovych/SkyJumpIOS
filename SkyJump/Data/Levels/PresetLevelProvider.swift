import Foundation

/// Будує рівень за пресетом. Однаковий пресет (seed, кількість, складність) — однаковий рівень.
struct PresetLevelProvider: LevelProviding {
    let preset: LevelPreset

    func makeLevel() -> [Platform] {
        RandomLevelProvider(platformCount: preset.platformCount,
                            verticalStep: preset.difficulty.verticalStep,
                            allowedTypes: preset.difficulty.allowedTypes,
                            generator: SeededRandomGenerator(seed: preset.seed))
            .makeLevel()
    }
}
