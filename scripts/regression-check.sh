#!/bin/bash
# Перевіряє, що демо-сценарій видає той самий результат, що й еталон.
# Збирає логіку гри (Domain, Data і форматування підсумку) в один файл,
# запускає демо через swift і порівнює вивід з scripts/baseline-demo-output.txt.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASELINE="$ROOT/scripts/baseline-demo-output.txt"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

find "$ROOT/SkyJump/Domain" "$ROOT/SkyJump/Data" -name '*.swift' -print0 \
    | sort -z | xargs -0 cat > "$WORK_DIR/main.swift"
cat "$ROOT/SkyJump/Presentation/Demo/GameSummaryFormatter.swift" >> "$WORK_DIR/main.swift"

cat >> "$WORK_DIR/main.swift" <<'SWIFT'

let report = GameSimulationService().simulate(playerName: "Doodler",
                                              level: DemoLevelProvider().makeLevel(),
                                              duration: 8)
report.log.forEach { print($0) }
print(GameSummaryFormatter().format(report.summary))
SWIFT

swift "$WORK_DIR/main.swift" > "$WORK_DIR/actual.txt"

if diff -u "$BASELINE" "$WORK_DIR/actual.txt"; then
    echo "OK: вивід демо-сценарію збігається з еталоном"
else
    echo "ПОМИЛКА: вивід демо-сценарію відрізняється від еталону" >&2
    exit 1
fi
