import Foundation

/// Composition root: єдине місце, де обираються конкретні реалізації сервісів.
/// Решта коду отримує їх через init і знає лише протоколи.
struct AppDependencies {
    let levelProvider: any LevelProviding
    let simulator: any GameSimulating
    let scoreStore: any ScoreStoring
    /// Бібліотека рівнів «Мої рівні» — спільна для всіх екранів.
    let library: LevelLibrary
    /// Радіо — одне на весь застосунок; каталог станцій — через протокол.
    let radio: RadioPlayer
    let radioProvider: any RadioStationProviding

    /// Залежності для реального запуску застосунку.
    /// Аргумент запуску `-randomLevel` (Edit Scheme → Run → Arguments) вмикає випадковий рівень.
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        let levelProvider: any LevelProviding = arguments.contains("-randomLevel")
            ? RandomLevelProvider()
            : DemoLevelProvider()

        // Журнал подій додатково дублюється в консоль Xcode
        return AppDependencies(levelProvider: levelProvider,
                               simulator: GameSimulationService(observers: [ConsoleEventLogger()]),
                               scoreStore: UserDefaultsScoreStore(defaults: .standard),
                               library: LevelLibrary(),
                               radio: RadioPlayer(streamer: AVPlayerStreamer()),
                               radioProvider: RadioBrowserClient())
    }

    func makeDemoViewModel() -> DemoViewModel {
        DemoViewModel(levelProvider: levelProvider,
                      simulator: simulator,
                      scoreStore: scoreStore)
    }
}
