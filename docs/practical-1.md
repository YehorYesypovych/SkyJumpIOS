# Практична робота 1

## Демо-сценарій

Створюється рівень з 10 платформ різних типів, гравець стрибає по них 8 секунд симуляції. Журнал подій виводиться на екран і в консоль Xcode, наприкінці — підсумок.

**Як перевірити:** запустити застосунок і натиснути «Запустити демо-сценарій». Очікувано: ламка платформа на висоті 360 ламається, пружина на висоті 450 підкидає гравця до ~930, платформи нижче екрана видаляються, рахунок ≈ 1290.

## Де в коді реалізовано конструкції Swift

| Конструкція | Де |
|---|---|
| `struct` | `Platform` (Models/Platform.swift), `Vector2` (Models/GameConfig.swift) |
| `class` | `Player` (Models/Player.swift), `GameSession` (Logic/GameSession.swift) |
| `protocol` | `GameObject` (Models/GameObject.swift) |
| `enum` | `PlatformType` (Models/PlatformType.swift), `GameConfig` |
| `let` / `var`, властивості | `Platform.id`, `Player.name` — константи; `position`, `velocity` — змінні; `Player.isFalling`, `GameSession.score` — обчислювані |
| Методи та ініціалізація | `Player.jump`, `Platform.update`; `init` у `Platform`, `Player`, `GameSession` |
| Колекції | `[Platform]`, `[String]`, `Dictionary(grouping:)` |
| Optional і безпечне розгортання | `PlatformType.jumpVelocity: Double?`; `if let` у `GameSession.init` і `handleLanding`; `??` у `summary()`; `guard` у `step` |
| Умовні конструкції | `if/else`, `guard`, `switch`, тернарний оператор |
### | Обробка колекцій | `firstIndex`, `removeAll`, `max`, `map`, `sorted`, `forEach`, `for` |
