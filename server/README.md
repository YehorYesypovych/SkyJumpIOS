# SkyJump Leaderboard — сервер таблиці лідерів

Навчальний сервер глобальної таблиці лідерів нескінченного режиму. Node.js 18+, лише вбудовані модулі — `npm install` не потрібен. Авторизації немає.

## Запуск

```bash
node server/index.js
```

Сервер слухає `http://localhost:8080` (на всіх інтерфейсах, тож доступний і з iPhone у тій самій Wi-Fi мережі). Дані зберігаються в `server/data/scores.json` — файл і папка створюються автоматично (у `.gitignore`).

Змінні оточення:

| Змінна | За замовчуванням | Що задає |
|---|---|---|
| `PORT` | `8080` | порт |
| `HOST` | `0.0.0.0` | інтерфейс |
| `DATA_FILE` | `server/data/scores.json` | файл з рахунками |

**Симулятор** звертається до `http://localhost:8080` без налаштувань. **iPhone**: у Xcode Edit Scheme → Run → Arguments додати `-serverURL http://<IP Mac>:8080` (IP — System Settings → Wi-Fi → Details).

## API

| Метод | Шлях | Параметри | Відповідь |
|---|---|---|---|
| `GET` | `/health` | — | `200 {"status":"ok"}` |
| `GET` | `/api/leaderboard` | `limit` 1…100 (20), `simulate` | `200 {"entries":[…]}` за спаданням рахунку; `400` при неправильному `limit` |
| `POST` | `/api/scores` | тіло JSON `{"player","score","theme"}` | `201 {"entry":{…},"rank":N}`; `400 {"error":"…"}` |

Запис таблиці:

```json
{ "id": "a79adada-4401-49cb-92bd-3b55be71ee45", "player": "Єгор", "score": 1200,
  "theme": "neonBeach", "createdAt": "2026-11-24T20:28:06Z" }
```

`createdAt` — ISO 8601 (UTC). При рівному рахунку вище той, хто набрав його раніше. `rank` — місце нового запису з 1.

Перевірка тіла `POST`: `player` — непорожній рядок до 20 символів (пробіли по краях обрізаються), `score` — ціле число ≥ 0, `theme` — непорожній рядок до 32 символів. Інакше `400` з поясненням у `error`.

### Режими перевірки (`simulate`, лише `GET /api/leaderboard`)

| Значення | Що повертає |
|---|---|
| `empty` | `200 {"entries":[]}` — порожня таблиця |
| `error` | `500 {"error":"…"}` |
| `broken` | `200` з обірваним JSON — клієнт не зможе розібрати відповідь |
| `slow` | звичайна відповідь із затримкою 3 с |

## Приклади `curl`

```bash
curl http://localhost:8080/health
```

```bash
curl "http://localhost:8080/api/leaderboard?limit=5"
```

```bash
curl -X POST http://localhost:8080/api/scores \
  -H "Content-Type: application/json" \
  -d '{"player":"Doodler","score":1500,"theme":"neonBeach"}'
```

```bash
curl -i "http://localhost:8080/api/leaderboard?simulate=error"
```

Щоб очистити таблицю, зупиніть сервер і видаліть `server/data/scores.json`.
