// SkyJump Leaderboard — навчальний сервер таблиці лідерів нескінченного режиму.
// Node.js 18+, лише вбудовані модулі: запуск без `npm install`.
//
//   node server/index.js            # http://localhost:8080
//   PORT=9000 node server/index.js  # інший порт
//
// Ендпоінти (докладніше — server/README.md):
//   GET  /health                               → 200 {"status":"ok"}
//   GET  /api/leaderboard?limit=20&simulate=…  → 200 {"entries":[…]} за спаданням рахунку
//   POST /api/scores  {"player","score","theme"} → 201 {"entry":{…},"rank":N} | 400 {"error":"…"}
//
// simulate=empty|error|broken|slow — режими перевірки станів клієнта.

'use strict';

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const PORT = Number(process.env.PORT) || 8080;
const HOST = process.env.HOST || '0.0.0.0'; // доступний і з iPhone у тій самій мережі
const DATA_FILE = process.env.DATA_FILE || path.join(__dirname, 'data', 'scores.json');

const LIMIT_DEFAULT = 20;
const LIMIT_MAX = 100;
const PLAYER_MAX_LENGTH = 20;
const THEME_MAX_LENGTH = 32;
const BODY_MAX_BYTES = 10 * 1024;
const SLOW_DELAY_MS = 3000;

// ---------- Сховище ----------

/** Читає всі записи з файлу; файлу ще немає — порожня таблиця. */
function loadScores() {
  try {
    const parsed = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    console.error(`Не вдалося прочитати ${DATA_FILE}: ${error.message}. Починаємо з порожньої таблиці.`);
    return [];
  }
}

/** Записує атомарно: спершу тимчасовий файл, потім перейменування. */
function saveScores(scores) {
  fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
  const tmp = `${DATA_FILE}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(scores, null, 2));
  fs.renameSync(tmp, DATA_FILE);
}

let scores = loadScores();

/** Більший рахунок — вище; при рівному рахунку вище той, хто набрав його раніше. */
function ranked() {
  return [...scores].sort((a, b) => b.score - a.score || a.createdAt.localeCompare(b.createdAt));
}

// ---------- Валідація ----------

/** Повертає текст помилки або null, якщо тіло правильне. */
function validateSubmission(body) {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return 'Тіло запиту має бути JSON-об\'єктом {"player","score","theme"}';
  }
  const { player, score, theme } = body;
  if (typeof player !== 'string' || player.trim().length === 0) {
    return 'Поле "player" — непорожній рядок';
  }
  if ([...player.trim()].length > PLAYER_MAX_LENGTH) {
    return `Поле "player" — не довше ${PLAYER_MAX_LENGTH} символів`;
  }
  if (!Number.isSafeInteger(score) || score < 0) {
    return 'Поле "score" — ціле число ≥ 0';
  }
  if (typeof theme !== 'string' || theme.length === 0 || theme.length > THEME_MAX_LENGTH) {
    return `Поле "theme" — непорожній рядок до ${THEME_MAX_LENGTH} символів`;
  }
  return null;
}

// ---------- HTTP ----------

function sendJSON(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

/** Відповідь, яку клієнт не зможе розібрати як JSON (simulate=broken). */
function sendBroken(res) {
  const body = '{"entries": [ {"id": "1", "player": "Broken"'; // обірваний JSON
  res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > BODY_MAX_BYTES) {
        reject(Object.assign(new Error('Тіло запиту завелике'), { status: 413 }));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Режим перевірки станів таблиці лідерів. Повертає true, якщо відповідь уже надіслано.
 * slow лише затримує відповідь — далі запит обробляється як звичайно.
 */
async function applySimulation(mode, res) {
  switch (mode) {
    case 'empty':
      sendJSON(res, 200, { entries: [] });
      return true;
    case 'error':
      sendJSON(res, 500, { error: 'Імітована помилка сервера (simulate=error)' });
      return true;
    case 'broken':
      sendBroken(res);
      return true;
    case 'slow':
      await delay(SLOW_DELAY_MS);
      return false;
    default:
      return false;
  }
}

async function handleLeaderboard(url, res) {
  if (await applySimulation(url.searchParams.get('simulate'), res)) return;

  const rawLimit = url.searchParams.get('limit');
  let limit = LIMIT_DEFAULT;
  if (rawLimit !== null) {
    limit = Number(rawLimit);
    if (!Number.isInteger(limit) || limit < 1 || limit > LIMIT_MAX) {
      sendJSON(res, 400, { error: `Параметр "limit" — ціле число від 1 до ${LIMIT_MAX}` });
      return;
    }
  }
  sendJSON(res, 200, { entries: ranked().slice(0, limit) });
}

async function handleSubmit(req, res) {
  const rawBody = await readBody(req);

  let body;
  try {
    body = JSON.parse(rawBody);
  } catch {
    sendJSON(res, 400, { error: 'Тіло запиту — некоректний JSON' });
    return;
  }
  const problem = validateSubmission(body);
  if (problem) {
    sendJSON(res, 400, { error: problem });
    return;
  }

  const entry = {
    id: crypto.randomUUID(),
    player: body.player.trim(),
    score: body.score,
    theme: body.theme,
    createdAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'), // ISO 8601 без мілісекунд
  };
  scores.push(entry);
  saveScores(scores);

  const rank = ranked().findIndex((item) => item.id === entry.id) + 1;
  sendJSON(res, 201, { entry, rank });
}

async function route(req, res) {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const key = `${req.method} ${url.pathname.replace(/\/+$/, '') || '/'}`;

  switch (key) {
    case 'GET /health':
      sendJSON(res, 200, { status: 'ok' });
      return;
    case 'GET /api/leaderboard':
      await handleLeaderboard(url, res);
      return;
    case 'POST /api/scores':
      await handleSubmit(req, res);
      return;
    default: {
      const known = ['/health', '/api/leaderboard', '/api/scores'].includes(url.pathname);
      sendJSON(res, known ? 405 : 404, { error: known ? 'Метод не підтримується' : 'Не знайдено' });
    }
  }
}

const server = http.createServer(async (req, res) => {
  const started = Date.now();
  try {
    await route(req, res);
  } catch (error) {
    if (!res.headersSent) {
      sendJSON(res, error.status || 500, { error: error.status ? error.message : 'Внутрішня помилка сервера' });
    }
    if (!error.status) console.error(error);
  } finally {
    console.log(`${req.method} ${req.url} → ${res.statusCode} (${Date.now() - started} мс)`);
  }
});

if (require.main === module) {
  server.listen(PORT, HOST, () => {
    console.log(`SkyJump Leaderboard: http://localhost:${PORT}  (записів: ${scores.length}, файл: ${DATA_FILE})`);
  });
}

module.exports = { server, validateSubmission };
