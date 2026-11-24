import Foundation
import Testing
@testable import SkyJump

@MainActor
struct ReachabilityTests {

    /// Перевіряє, що кожна наступна платформа досяжна з попередньої.
    private func expectReachable(_ platforms: [Platform]) {
        let sorted = platforms.sorted { $0.position.y < $1.position.y }
        for (lower, upper) in zip(sorted, sorted.dropFirst()) {
            let vertical = upper.position.y - lower.position.y
            let horizontal = Reachability.wrappedDistance(lower.position.x + lower.width / 2,
                                                          upper.position.x + upper.width / 2)
            #expect(vertical <= Reachability.maxVerticalGap)
            #expect(horizontal <= Reachability.maxHorizontalGap + 0.001)
        }
    }

    @Test func presetLevelsArePassable() {
        for preset in LevelPreset.samples {
            expectReachable(PresetLevelProvider(preset: preset).makeLevel())
        }
        // і будь-які рівні з редактора: різні seed, складності й кількість платформ
        for seed in UInt64(1)...40 {
            for difficulty in LevelDifficulty.allCases {
                var preset = LevelPreset.makeNew()
                preset.seed = seed
                preset.difficulty = difficulty
                preset.platformCount = 50
                expectReachable(PresetLevelProvider(preset: preset).makeLevel())
            }
        }
    }

    @Test func endlessLevelIsPassable() {
        let generator = EndlessLevelGenerator(seed: 99)
        let start = generator.start()
        let rest = generator.extend(upTo: 15_000)
        expectReachable(start.platforms + rest.platforms)
    }

    @Test func wrappedDistanceGoesThroughEdge() {
        #expect(Reachability.wrappedDistance(10, 390) == 20)
        #expect(Reachability.wrappedDistance(100, 300) == 200)
        #expect(Reachability.wrappedDistance(50, 120) == 70)
    }

    @Test func movingLeftThroughEdgeAppearsOnRightSmoothly() {
        let player = Player(name: "Doodler", startPosition: Vector2(x: 5, y: 100), gravity: 0)
        player.move(direction: -1)
        player.update(deltaTime: 0.1)   // 28 одиниць уліво: 5 − 28 = −23 → 377

        #expect(abs(player.position.x - (GameConfig.worldWidth - 23)) < 0.001)
    }

    @Test func feetLandAcrossWorldEdge() {
        // платформа біля правого краю, а персонаж щойно перейшов на лівий бік
        let platforms = [Platform(id: 0, x: GameConfig.worldWidth - GameConfig.platformWidth, y: 0)]
        let session = GameSession(playerName: "Doodler", platforms: platforms,
                                  completesAtTop: true, footWidth: GameRound.footWidth)
        session.player.position = Vector2(x: 4, y: 40)

        for _ in 0..<30 {
            session.step(deltaTime: 1.0 / 60.0)
        }

        #expect(session.player.jumpsCount == 1)
    }
}
