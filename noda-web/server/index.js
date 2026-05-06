import { createServer } from 'node:http';
import { createCipheriv, createHash, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, statSync } from 'node:fs';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const rootDir = resolve(__dirname, '..');
const distDir = resolve(rootDir, 'dist');
const dataDir = resolve(rootDir, 'data');
const dbPath = resolve(dataDir, 'noda.sqlite');
const port = Number(process.env.PORT || 4177);
const sessionCookie = 'noda_session';
const sessionTtlMs = 1000 * 60 * 60 * 24 * 30;
const appSecret = process.env.NODA_SECRET || 'noda-local-dev-secret-change-me';

const tariffs = [
  { id: 'month', title: 'Подписка на 30 дней', duration: '1 месяц', devices: 3, traffic: '∞', price: 149, popular: true },
  { id: 'quarter', title: 'Подписка на 90 дней', duration: '3 месяца', devices: 5, traffic: '∞', price: 399, popular: false },
  { id: 'year', title: 'Подписка на 365 дней', duration: '12 месяцев', devices: 8, traffic: '∞', price: 1290, popular: false },
];

const words = [
  'noda', 'orbit', 'velvet', 'north', 'silent', 'relay', 'glass', 'cipher',
  'polar', 'delta', 'lumen', 'route', 'nexus', 'cloud', 'pulse', 'vault',
  'signal', 'vector', 'mirror', 'river', 'summit', 'nova', 'quiet', 'field',
];

mkdirSync(dataDir, { recursive: true });
const db = new DatabaseSync(dbPath);
db.exec(`
  PRAGMA journal_mode = WAL;
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    phrase_hash TEXT NOT NULL UNIQUE,
    phrase_cipher TEXT NOT NULL,
    phrase_salt TEXT NOT NULL,
    ref_code TEXT NOT NULL UNIQUE,
    subscription_status TEXT NOT NULL DEFAULT 'inactive',
    subscription_until TEXT,
    created_at TEXT NOT NULL,
    imported_at TEXT
  );
  CREATE TABLE IF NOT EXISTS sessions (
    token_hash TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    expires_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS invoices (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tariff_id TEXT NOT NULL,
    title TEXT NOT NULL,
    amount INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT NOT NULL
  );
`);

function nowIso() {
  return new Date().toISOString();
}

function publicUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    refCode: row.ref_code,
    subscriptionStatus: row.subscription_status,
    subscriptionUntil: row.subscription_until,
    createdAt: row.created_at,
    importedAt: row.imported_at,
  };
}

function createId(prefix) {
  return `${prefix}_${randomBytes(8).toString('hex')}`;
}

function normalizePhrase(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[—–_\\s]+/g, '-')
    .split('-')
    .filter(Boolean)
    .join('-');
}

function hashPhrase(phrase, salt) {
  return scryptSync(phrase, salt, 32).toString('hex');
}

function encryptPhrase(phrase) {
  const key = scryptSync(appSecret, 'noda-phrase-store', 32);
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(phrase, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('base64url')}.${tag.toString('base64url')}.${encrypted.toString('base64url')}`;
}

function createPhrase() {
  const picked = ['noda'];
  while (picked.length < 6) {
    const word = words[Math.floor(Math.random() * words.length)];
    if (!picked.includes(word)) picked.push(word);
  }
  return picked.join('-');
}

function createSession(userId) {
  const token = randomBytes(32).toString('base64url');
  const tokenHash = createHash('sha256').update(`${appSecret}:${token}`).digest('hex');
  const createdAt = nowIso();
  const expiresAt = new Date(Date.now() + sessionTtlMs).toISOString();
  db.prepare('INSERT INTO sessions (token_hash, user_id, created_at, expires_at) VALUES (?, ?, ?, ?)')
    .run(tokenHash, userId, createdAt, expiresAt);
  return token;
}

function sessionCookieHeader(token) {
  const secure = process.env.NODE_ENV === 'production' ? '; Secure' : '';
  return `${sessionCookie}=${token}; HttpOnly; SameSite=Lax; Path=/; Max-Age=${Math.floor(sessionTtlMs / 1000)}${secure}`;
}

function clearSessionCookieHeader() {
  return `${sessionCookie}=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0`;
}

function getCookie(req, name) {
  const cookie = req.headers.cookie || '';
  for (const part of cookie.split(';')) {
    const [key, ...rest] = part.trim().split('=');
    if (key === name) return rest.join('=');
  }
  return null;
}

function getSession(req) {
  const token = getCookie(req, sessionCookie);
  if (!token) return null;
  const tokenHash = createHash('sha256').update(`${appSecret}:${token}`).digest('hex');
  const row = db.prepare(`
    SELECT sessions.token_hash, sessions.expires_at, users.*
    FROM sessions
    JOIN users ON users.id = sessions.user_id
    WHERE sessions.token_hash = ?
  `).get(tokenHash);
  if (!row) return null;
  if (new Date(row.expires_at).getTime() < Date.now()) {
    db.prepare('DELETE FROM sessions WHERE token_hash = ?').run(tokenHash);
    return null;
  }
  return row;
}

function requireSession(req, res) {
  const session = getSession(req);
  if (!session) {
    sendJson(res, 401, { error: 'auth_required' });
    return null;
  }
  return session;
}

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    const error = new Error('invalid_json');
    error.statusCode = 400;
    throw error;
  }
}

function sendJson(res, status, payload, headers = {}) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    ...headers,
  });
  res.end(JSON.stringify(payload));
}

function sendError(res, error) {
  const status = error.statusCode || 500;
  sendJson(res, status, { error: error.message || 'server_error' });
}

function safeCompare(a, b) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}

function listInvoices(userId) {
  return db.prepare(`
    SELECT id, tariff_id, title, amount, status, created_at
    FROM invoices
    WHERE user_id = ?
    ORDER BY created_at DESC
  `).all(userId).map((invoice) => ({
    id: invoice.id,
    tariffId: invoice.tariff_id,
    title: invoice.title,
    amount: invoice.amount,
    status: invoice.status,
    createdAt: invoice.created_at,
  }));
}

async function handleApi(req, res, url) {
  try {
    if (req.method === 'GET' && url.pathname === '/api/session') {
      const session = getSession(req);
      return sendJson(res, 200, { user: publicUser(session) });
    }

    if (req.method === 'POST' && url.pathname === '/api/auth/generate') {
      let phrase = createPhrase();
      let normalized = normalizePhrase(phrase);
      let salt = randomBytes(16).toString('hex');
      let phraseHash = hashPhrase(normalized, salt);

      while (db.prepare('SELECT id FROM users WHERE phrase_hash = ?').get(phraseHash)) {
        phrase = createPhrase();
        normalized = normalizePhrase(phrase);
        salt = randomBytes(16).toString('hex');
        phraseHash = hashPhrase(normalized, salt);
      }

      const userId = createId('usr');
      const refCode = `NODA-${randomBytes(3).toString('hex').toUpperCase()}`;
      const createdAt = nowIso();
      db.prepare(`
        INSERT INTO users (id, phrase_hash, phrase_cipher, phrase_salt, ref_code, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(userId, phraseHash, encryptPhrase(phrase), salt, refCode, createdAt);

      const token = createSession(userId);
      const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
      return sendJson(res, 201, { user: publicUser(user), phrase }, { 'Set-Cookie': sessionCookieHeader(token) });
    }

    if (req.method === 'POST' && url.pathname === '/api/auth/login') {
      const body = await readJson(req);
      const phrase = normalizePhrase(body.phrase);
      if (phrase.split('-').length !== 6) {
        return sendJson(res, 400, { error: 'phrase_must_have_6_words' });
      }

      const users = db.prepare('SELECT * FROM users').all();
      const user = users.find((candidate) => safeCompare(hashPhrase(phrase, candidate.phrase_salt), candidate.phrase_hash));
      if (!user) return sendJson(res, 401, { error: 'invalid_phrase' });

      const token = createSession(user.id);
      return sendJson(res, 200, { user: publicUser(user) }, { 'Set-Cookie': sessionCookieHeader(token) });
    }

    if (req.method === 'POST' && url.pathname === '/api/logout') {
      const token = getCookie(req, sessionCookie);
      if (token) {
        const tokenHash = createHash('sha256').update(`${appSecret}:${token}`).digest('hex');
        db.prepare('DELETE FROM sessions WHERE token_hash = ?').run(tokenHash);
      }
      return sendJson(res, 200, { ok: true }, { 'Set-Cookie': clearSessionCookieHeader() });
    }

    if (req.method === 'GET' && url.pathname === '/api/dashboard') {
      const session = requireSession(req, res);
      if (!session) return;
      return sendJson(res, 200, {
        user: publicUser(session),
        invoices: listInvoices(session.id),
        tariffs,
      });
    }

    if (req.method === 'POST' && url.pathname === '/api/invoices') {
      const session = requireSession(req, res);
      if (!session) return;
      const body = await readJson(req);
      const tariff = tariffs.find((item) => item.id === body.tariffId) || tariffs[0];
      const invoiceId = randomBytes(16).toString('hex');
      const createdAt = nowIso();
      db.prepare(`
        INSERT INTO invoices (id, user_id, tariff_id, title, amount, status, created_at)
        VALUES (?, ?, ?, ?, ?, 'pending', ?)
      `).run(invoiceId, session.id, tariff.id, tariff.title, tariff.price, createdAt);
      return sendJson(res, 201, {
        invoice: {
          id: invoiceId,
          tariffId: tariff.id,
          title: tariff.title,
          amount: tariff.price,
          status: 'pending',
          createdAt,
        },
        paymentEnabled: false,
      });
    }

    if (req.method === 'GET' && url.pathname === '/api/invoices') {
      const session = requireSession(req, res);
      if (!session) return;
      return sendJson(res, 200, { invoices: listInvoices(session.id) });
    }

    const invoiceMatch = url.pathname.match(/^\/api\/invoices\/([^/]+)$/);
    if (req.method === 'GET' && invoiceMatch) {
      const session = requireSession(req, res);
      if (!session) return;
      const invoice = db.prepare(`
        SELECT id, tariff_id, title, amount, status, created_at
        FROM invoices
        WHERE id = ? AND user_id = ?
      `).get(invoiceMatch[1], session.id);
      if (!invoice) return sendJson(res, 404, { error: 'invoice_not_found' });
      return sendJson(res, 200, {
        invoice: {
          id: invoice.id,
          tariffId: invoice.tariff_id,
          title: invoice.title,
          amount: invoice.amount,
          status: invoice.status,
          createdAt: invoice.created_at,
        },
        paymentEnabled: false,
      });
    }

    if (req.method === 'POST' && url.pathname === '/api/import') {
      const session = requireSession(req, res);
      if (!session) return;
      const body = await readJson(req);
      const importCode = String(body.importCode || '').trim();
      if (importCode.length < 4) return sendJson(res, 400, { error: 'import_code_required' });
      const importedAt = nowIso();
      db.prepare(`
        UPDATE users
        SET imported_at = ?, subscription_status = 'active', subscription_until = ?
        WHERE id = ?
      `).run(importedAt, new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString(), session.id);
      const user = db.prepare('SELECT * FROM users WHERE id = ?').get(session.id);
      return sendJson(res, 200, { user: publicUser(user), imported: true });
    }

    return sendJson(res, 404, { error: 'not_found' });
  } catch (error) {
    return sendError(res, error);
  }
}

function serveStatic(req, res, url) {
  if (!existsSync(distDir)) {
    res.writeHead(503, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Build is missing. Run npm run build first.');
    return;
  }

  const requested = url.pathname === '/' ? '/index.html' : decodeURIComponent(url.pathname);
  const filePath = normalize(join(distDir, requested));
  const resolvedPath = resolve(filePath);
  if (!resolvedPath.startsWith(distDir)) {
    res.writeHead(403);
    res.end();
    return;
  }

  let target = resolvedPath;
  if (!existsSync(target) || statSync(target).isDirectory()) {
    target = join(distDir, 'index.html');
  }

  const ext = extname(target);
  const types = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.svg': 'image/svg+xml',
    '.png': 'image/png',
    '.ico': 'image/x-icon',
  };

  res.writeHead(200, {
    'Content-Type': types[ext] || 'application/octet-stream',
    'Cache-Control': ext === '.html' ? 'no-store' : 'public, max-age=31536000, immutable',
  });
  res.end(readFileSync(target));
}

createServer((req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  if (url.pathname.startsWith('/api/')) {
    void handleApi(req, res, url);
    return;
  }
  serveStatic(req, res, url);
}).listen(port, '0.0.0.0', () => {
  console.log(`noda web server: http://localhost:${port}`);
  console.log(`database: ${dbPath}`);
});
