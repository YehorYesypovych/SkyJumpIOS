import Foundation

/// Перетворює підсумок гри на текст для екрана.
struct GameSummaryFormatter {
    func format(_ summary: GameSummary) -> String {
        let status = summary.isAlive ? "у грі" : "впав"
        let topPlatformInfo = summary.highestPlatformY.map { "\(Int($0))" } ?? "немає"
        let typesLeft = summary.platformsLeft
            .map { "\($0.key.title): \($0.value)" }
            .sorted()
            .joined(separator: ", ")

        return """
        Гравець: \(summary.playerName) (\(status))
        Рахунок (макс. висота): \(summary.score)
        Стрибків: \(summary.jumpsCount), зламано платформ: \(summary.brokenPlatformsCount)
        Найвища платформа: \(topPlatformInfo)
        Залишилось платформ: \(typesLeft.isEmpty ? "немає" : typesLeft)
        """
    }
}
