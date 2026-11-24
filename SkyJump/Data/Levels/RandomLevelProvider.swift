import Foundation

/// Випадковий рівень. Генератор випадкових чисел передається ззовні:
/// у грі — системний, у тестах і демо — з фіксованим seed, щоб рівень повторювався.
final class RandomLevelProvider<Generator: RandomNumberGenerator>: LevelProviding {
    private let platformCount: Int
    private let verticalStep: Double
    private let allowedTypes: [PlatformType]
    private var generator: Generator

    /// allowedTypes — типи платформ, з яких випадково обирається кожна платформа (крім першої).
    init(platformCount: Int = 20,
         verticalStep: Double = 110,
         allowedTypes: [PlatformType] = PlatformType.allCases,
         generator: Generator) {
        self.platformCount = max(platformCount, 1)
        self.verticalStep = verticalStep
        self.allowedTypes = allowedTypes
        self.generator = generator
    }

    func makeLevel() -> [Platform] {
        // перша платформа завжди звичайна і по центру — з неї стартує гравець
        var builder = LevelBuilder().platform(.normal, x: 160, y: 0)
        var previousX = 160.0
        // крок не більший за той, на який реально можна стрибнути
        let step = min(verticalStep, Reachability.maxVerticalGap)

        for index in 1..<platformCount {
            let type = allowedTypes.randomElement(using: &generator) ?? .normal
            // наступна платформа завжди в межах досяжності від попередньої
            let x = Reachability.nextPlatformX(after: previousX, using: &generator)
            builder = builder.platform(type, x: x, y: Double(index) * step)
            previousX = x
        }
        return builder.build()
    }
}

extension RandomLevelProvider where Generator == SystemRandomNumberGenerator {
    convenience init(platformCount: Int = 20,
                     verticalStep: Double = 110,
                     allowedTypes: [PlatformType] = PlatformType.allCases) {
        self.init(platformCount: platformCount,
                  verticalStep: verticalStep,
                  allowedTypes: allowedTypes,
                  generator: SystemRandomNumberGenerator())
    }
}
