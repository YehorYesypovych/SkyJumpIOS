import Foundation

/// Composition root: єдине місце, де обираються конкретні реалізації сервісів.
/// Решта коду отримує їх через init і знає лише протоколи.
struct AppDependencies {
    let levelProvider: any LevelProviding
    let simulator: any GameSimulating
    let scoreStore: any ScoreStoring
    /// Рекорд нескінченного режиму — окремо від рекордів рівнів.
    let endlessScores: any ScoreStoring
    /// Бібліотека рівнів «Мої рівні» — спільна для всіх екранів.
    let library: LevelLibrary
    /// Радіо — одне на весь застосунок; каталог станцій — через протокол.
    let radio: RadioPlayer
    let radioProvider: any RadioStationProviding
    /// Тема, скін і слід гравця.
    let cosmetics: CosmeticsSettings
    /// Таблиця лідерів на власному сервері і куди віддати рахунок після нескінченної гри.
    let leaderboard: any LeaderboardProviding
    let scoreReporter: (any ScoreReporting)?
    /// Нік гравця для таблиці лідерів.
    var profile = PlayerProfile()

    /// Залежності для реального запуску застосунку.
    /// Аргумент запуску `-randomLevel` (Edit Scheme → Run → Arguments) вмикає випадковий рівень.
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        let levelProvider: any LevelProviding = arguments.contains("-randomLevel")
            ? RandomLevelProvider()
            : DemoLevelProvider()

        // Таблиця лідерів: власний сервер через мережевий компонент.
        // Аргумент `-leaderboardSimulate empty|error|broken|slow` вмикає режим перевірки на сервері.
        let cosmetics = CosmeticsSettings()
        let profile = PlayerProfile()
        let leaderboard = LeaderboardClient(http: URLSessionHTTPClient(baseURL: ServerConfig.baseURL()),
                                            simulate: UserDefaults.standard.string(forKey: "leaderboardSimulate"))
        let reporter = LeaderboardScoreReporter(provider: leaderboard, profile: profile, cosmetics: cosmetics)

        // Журнал подій додатково дублюється в консоль Xcode
        return AppDependencies(levelProvider: levelProvider,
                               simulator: GameSimulationService(observers: [ConsoleEventLogger()]),
                               scoreStore: UserDefaultsScoreStore(defaults: .standard),
                               endlessScores: UserDefaultsScoreStore(defaults: .standard, key: "endlessBestScore"),
                               library: LevelLibrary(),
                               radio: RadioPlayer(streamer: AVPlayerStreamer()),
                               radioProvider: RadioBrowserClient(),
                               cosmetics: cosmetics,
                               leaderboard: leaderboard,
                               scoreReporter: reporter,
                               profile: profile)
    }

    func makeDemoViewModel() -> DemoViewModel {
        DemoViewModel(levelProvider: levelProvider,
                      simulator: simulator,
                      scoreStore: scoreStore)
    }
}
