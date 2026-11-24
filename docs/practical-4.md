# Практична робота 4

Взаємодія із сервером та обробка даних. Виконували вдвох: **Kolya Kulchytskyi** (частина A) і **Єгор Єсипович** (частина B).

## 1. Джерела даних

### 1.1 Radio Browser (відкрите API)
Відкритий каталог інтернет-радіо [radio-browser.info](https://www.radio-browser.info). Використовується на екрані «Радіо» — станції synthwave, retrowave, vaporwave, 80s, chillwave.

| | |
|---|---|
| Базова адреса | `https://de1.api.radio-browser.info`, запасні — `de2`, `fi1` (дзеркала одного каталогу) |
| Endpoint | `GET /json/stations/bytag/{tag}` |
| Параметри | `hidebroken=true` — без зламаних станцій; `order=clickcount&reverse=true` — найпопулярніші першими; `limit=25` |
| Авторизація | не потрібна; каталог просить представлятися, тому надсилається `User-Agent: SkyJump/1.0` |
| Формат | JSON-масив станцій |

Приклад запиту:

```
GET https://de1.api.radio-browser.info/json/stations/bytag/synthwave?hidebroken=true&order=clickcount&reverse=true&limit=25
```

Приклад відповіді (скорочено, лише поля, які читає застосунок):

```json
[
  {
    "stationuuid": "9617a958-0601-11e8-ae97-52543be04c81",
    "name": "Nightride FM",
    "url": "https://stream.nightride.fm/nightride.m4a",
    "url_resolved": "https://stream.nightride.fm/nightride.m4a",
    "country": "Canada", "countrycode": "CA",
    "tags": "synthwave,retrowave,80s",
    "favicon": "https://nightride.fm/favicon.png",
    "codec": "AAC", "bitrate": 128,
    "lastcheckok": 1, "clickcount": 812
  }
]
```

Відповідь декодується в `RadioBrowserStationDTO` (`Data/Radio/RadioBrowserClient.swift`): `url_resolved` перейменовано через `CodingKeys`, необов'язкові поля — `Optional`. Далі `RadioStationMapper` залишає лише те, що справді можна відтворити: лише `https`, кодеки MP3 / AAC / AAC+ / HLS, остання перевірка каталогу пройдена, без дублів за назвою.

### 1.2 SkyJump Leaderboard (власний сервер)
<!-- Частина B: запуск сервера, endpoints, формат, simulate -->

## 2. Мережевий шар
Мережа винесена в окремий компонент, екрани й ViewModel з `URLSession` не працюють.

```
RadioView ── RadioViewModel ── RadioStationProviding ── RadioBrowserClient ── [HTTPClient] ── URLSession
                                (протокол)                (Data/Radio)          (протокол)
```

| Тип | Файл | Роль |
|---|---|---|
| `HTTPClient` | `Domain/Contracts/HTTPClient.swift` | протокол: `send(_:as:) async throws -> T` для будь-якої `Decodable`-моделі |
| `HTTPRequest`, `HTTPMethod` | там само | метод, шлях, параметри, заголовки, тіло — без прив'язки до URLSession |
| `NetworkError` | там само | `transport(URLError.Code)`, `httpStatus(Int)`, `decoding(String)`, `invalidResponse` |
| `URLSessionHTTPClient` | `Data/Network/URLSessionHTTPClient.swift` | реалізація на `URLSession`: базова адреса, заголовки за замовчуванням, таймаут, декодер |
| `NetworkError.userMessage` | `Presentation/Common/NetworkError+Message.swift` | текст помилки для користувача |
| `LoadState<Value>` | `Presentation/Common/LoadState.swift` | стан екрана: `idle`, `loading`, `loaded`, `empty`, `failed` |

**Порядок обробки відповіді** в `URLSessionHTTPClient.data(for:)`:

1. Запит не відбувся (`URLError`: немає інтернету, таймаут, хост недоступний) → `NetworkError.transport(code)`.
2. Відповідь не HTTP → `.invalidResponse`.
3. Статус не `2xx` → `.httpStatus(code)`. **Тіло такої відповіді не декодується як успішні дані**: сторінка помилки чи JSON з кодом 404 не перетвориться на «порожній список».
4. Лише після цього — `JSONDecoder`. `DecodingError` → `.decoding(опис)`, де опис каже, якого поля не вистачило або який тип не збігся (`URLSessionHTTPClient.describe`).

Скасування запиту (`URLError.cancelled`, `CancellationError`) помилкою для користувача не вважається — екран просто закрили.

**Перебір дзеркал Radio Browser.** `RadioBrowserClient` отримує через `init` масив `[any HTTPClient]` — по одному на сервер. Якщо сервер недоступний (`transport`, `invalidResponse`) або відповів `5xx`, пробується наступний. Помилка формату чи `4xx` іншим сервером не виправиться, тому віддається одразу (`RadioBrowserClient.shouldTryNextServer`). Жанр, що не завантажився, не ламає весь список: помилка — лише якщо не вдався жоден запит.

**Передавання залежностей.** Конкретні реалізації обираються лише в composition root:

```swift
// AppDependencies.live()
radioProvider: RadioBrowserClient(clients: RadioBrowserClient.liveClients()),
```

`ScreenFactory` передає `dependencies.radioProvider` у `RadioViewModel(provider:player:)`. У Preview і тестах замість мережі — `StubRadioProvider`, `StubStationsProvider` або `ScriptedHTTPClient`; код ViewModel при цьому не змінюється.

## 3. Стани екранів і помилки

### 3.1 Радіо

`RadioViewModel.state: LoadState<[RadioStation]>` — єдине джерело стану екрана.

| Стан | Коли | Що бачить користувач |
|---|---|---|
| `.idle` / `.loading` | перше відкриття, повтор після помилки | «Шукаємо хвилі…» з індикатором; повзунок гучності, жанри й кнопка «Назад» доступні |
| `.loaded(stations)` | каталог повернув станції | список станцій, фільтр за жанром, міні-плеєр |
| `.empty` | каталог відповів, але придатних станцій немає | «Ефір порожній» і кнопка «Оновити» |
| `.failed(message)` | помилка мережі, сервера чи формату | «Радіо мовчить», текст причини і кнопка «Спробувати ще раз» |

Порожня відповідь — **не помилка**: `RadioBrowserClient.stations(for:)` повертає `[]`, а ViewModel переводить екран у `.empty`.

Під час «потягни, щоб оновити» вже показаний список лишається на екрані, поки йде запит. Повторне натискання під час завантаження ігнорується; якщо стартував новий запит (наприклад, у режимі перевірки), відповідь попереднього відкидається.

Тексти помилок (`NetworkError.userMessage`) різні для різних причин, технічні подробиці (назва поля JSON) не показуються:

| Помилка | Текст |
|---|---|
| `transport(.notConnectedToInternet)` | Немає інтернету. Перевір з'єднання і спробуй ще раз. |
| `transport(.timedOut)` | Сервер довго не відповідає. Спробуй ще раз. |
| `transport(.cannotConnectToHost)` | Сервер недоступний. Спробуй трохи згодом. |
| `httpStatus(5xx)` | Помилка на сервері (код 500). Спробуй трохи згодом. |
| `httpStatus(4xx)` | Сервер відхилив запит (код 404). |
| `decoding`, `invalidResponse` | Сервер надіслав неочікувану відповідь. Спробуй трохи згодом. |

### 3.2 Лідери
<!-- Частина B -->

## 4. Як перевірити

### 4.1 Радіо

**Справжній API.** Запустити застосунок, у тулбарі списку рівнів відкрити «Радіо». З'являється «Шукаємо хвилі…», потім список станцій. Тап по станції вмикає її; «потягни вниз» оновлює список.

**Контрольовані стани.** У Debug-збірці в тулбарі екрана «Радіо» є меню режиму перевірки (іконка жучка). Пункт перемикає джерело на `StubRadioProvider` з потрібним сценарієм і одразу перезавантажує екран; над повзунком гучності з'являється підпис «Перевірка: …».

| Пункт меню | Очікуваний результат |
|---|---|
| Справжній API | реальний запит до Radio Browser, список станцій |
| Тестові станції | три тестові станції без мережі |
| Порожня відповідь | «Ефір порожній» + «Оновити» |
| Немає мережі | «Радіо мовчить» — «Немає інтернету…» + «Спробувати ще раз» |
| HTTP 500 | «Помилка на сервері (код 500)…» |
| Пошкоджений JSON | справжнє декодування зіпсованої станції → «Сервер надіслав неочікувану відповідь…» |
| Повільна відповідь | 3 секунди індикатора, під час яких можна піти назад чи змінити гучність, потім список |

**Справжня відсутність мережі.** Вимкнути Wi-Fi на Mac (або Network Link Conditioner → 100% Loss), відкрити «Радіо» вперше після запуску — «Немає інтернету…»; увімкнути мережу і натиснути «Спробувати ще раз» — список.

### 4.2 Лідери
<!-- Частина B: сервер, надсилання рахунку, порожньо, помилки -->

## 5. Тести

Запуск: ⌘U у Xcode.

**Мережевий клієнт** — `SkyJumpTests/URLSessionHTTPClientTests.swift`. Справжній `URLSessionHTTPClient`, але `URLSession` налаштована на `StubURLProtocol`: відповідь задає тест, у мережу запит не йде.

| Тест | Що перевіряє |
|---|---|
| `validJSONIsDecoded` | 200 + коректний JSON → модель |
| `serverErrorIsReportedBeforeDecoding` | 500 з HTML-тілом → `.httpStatus(500)`, а не помилка декодування |
| `clientErrorStatusIsReported` | 404 з коректним JSON не вважається успіхом |
| `invalidJSONIsDecodingError` | 200 + JSON не тієї форми → `.decoding` з описом |
| `noInternetIsTransportError` | `URLError(.notConnectedToInternet)` → `.transport` |
| `requestReachesNetworkWithPathQueryAndHeaders` | шлях дописується до базового, параметри, `User-Agent`, `Accept`, власні заголовки |
| `postRequestCarriesBody` | метод POST і тіло запиту |
| `NetworkErrorMessageTests` | різні причини — різні тексти, без технічних подробиць |

**Радіо** — `SkyJumpTests/RadioTests.swift`.

| Набір | Що перевіряє |
|---|---|
| `RadioStationMapperTests` | відбір станцій, поля, зібраний запит до каталогу |
| `RadioBrowserClientTests` | перехід на наступне дзеркало при недоступності і `5xx`; помилка формату не повторюється; усі сервери недоступні → помилка; порожня відповідь → `[]` |
| `RadioViewModelTests` | дані, порожньо, помилка з кодом, повтор після помилки, усі сценарії режиму перевірки, фільтр за жанром |

## 6. Хто що робив
<!-- Частина A, у фіналі -->
