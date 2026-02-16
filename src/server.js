const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { URL } = require('url');

const DEFAULT_DATA_PATH = path.join(__dirname, '..', 'data', 'db.json');
const STATIC_DIR = path.join(__dirname, '..', 'public');
const MAX_BODY_SIZE = 25 * 1024 * 1024;
const SESSION_DURATION_MS = 1000 * 60 * 60 * 8;
const MAX_LOGIN_ATTEMPTS = 5;
const LOGIN_LOCK_WINDOW_MS = 1000 * 60 * 5;

function loadDb(dataPath) {
  if (!fs.existsSync(dataPath)) {
    const initial = {
      user: null,
      sessions: [],
      documents: [],
      versions: [],
      settings: { reminderDays: 30 },
      counters: { doc: 1, version: 1 }
    };
    fs.writeFileSync(dataPath, JSON.stringify(initial, null, 2));
    return initial;
  }
  return JSON.parse(fs.readFileSync(dataPath, 'utf8'));
}

function saveDb(dataPath, db) {
  fs.writeFileSync(dataPath, JSON.stringify(db, null, 2));
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const contentLength = Number(req.headers['content-length'] || 0);
    if (contentLength > MAX_BODY_SIZE) {
      reject(new Error('Payload too large'));
      return;
    }
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > MAX_BODY_SIZE) {
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error('Invalid JSON'));
      }
    });
    req.on('error', reject);
  });
}

function sendJson(res, status, payload) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store'
  });
  res.end(JSON.stringify(payload));
}

function hashPin(pin, salt) {
  return crypto.pbkdf2Sync(pin, salt, 100000, 32, 'sha256').toString('hex');
}

function sanitizeDocument(doc) {
  return {
    id: doc.id,
    name: doc.name,
    category: doc.category,
    isPermanent: doc.isPermanent,
    expiryDate: doc.expiryDate,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
    latestVersion: doc.latestVersion
  };
}

function getStatus(document, now = new Date()) {
  if (document.isPermanent || !document.expiryDate) return 'permanent';
  const expiry = new Date(document.expiryDate);
  if (expiry < now) return 'expired';
  return 'valid';
}

function daysUntil(date, now = new Date()) {
  const dateMs = new Date(date).setHours(0, 0, 0, 0);
  const nowMs = new Date(now).setHours(0, 0, 0, 0);
  return Math.ceil((dateMs - nowMs) / (1000 * 60 * 60 * 24));
}

function createServer(options = {}) {
  const dataPath = options.dataPath || DEFAULT_DATA_PATH;
  const staticDir = options.staticDir || STATIC_DIR;
  const ensureDir = path.dirname(dataPath);
  const loginAttempts = new Map();
  if (!fs.existsSync(ensureDir)) fs.mkdirSync(ensureDir, { recursive: true });

  const server = http.createServer(async (req, res) => {
    try {
      const url = new URL(req.url, 'http://localhost');
      let db = loadDb(dataPath);

      if (req.method === 'GET' && (url.pathname === '/' || url.pathname.startsWith('/assets/') || url.pathname === '/app.js' || url.pathname === '/styles.css')) {
        const requested = url.pathname === '/' ? '/index.html' : url.pathname;
        const fullPath = path.join(staticDir, requested);
        if (!fullPath.startsWith(staticDir) || !fs.existsSync(fullPath)) {
          res.writeHead(404);
          res.end('Not found');
          return;
        }
        const ext = path.extname(fullPath);
        const types = {
          '.html': 'text/html; charset=utf-8',
          '.js': 'application/javascript; charset=utf-8',
          '.css': 'text/css; charset=utf-8'
        };
        res.writeHead(200, { 'Content-Type': types[ext] || 'text/plain; charset=utf-8' });
        res.end(fs.readFileSync(fullPath));
        return;
      }

      if (req.method === 'GET' && url.pathname === '/api/health') {
        sendJson(res, 200, { ok: true });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/api/auth/setup-pin') {
        const body = await readJsonBody(req);
        const pin = String(body.pin || '');
        if (!/^\d{4,8}$/.test(pin)) {
          sendJson(res, 400, { error: 'PIN must be 4-8 digits' });
          return;
        }
        if (db.user) {
          sendJson(res, 409, { error: 'PIN already configured' });
          return;
        }
        const salt = crypto.randomBytes(16).toString('hex');
        db.user = { id: 1, salt, pinHash: hashPin(pin, salt), createdAt: new Date().toISOString() };
        saveDb(dataPath, db);
        sendJson(res, 201, { ok: true });
        return;
      }

      if (req.method === 'POST' && url.pathname === '/api/auth/login') {
        const body = await readJsonBody(req);
        const pin = String(body.pin || '');
        const loginKey = req.socket.remoteAddress || 'unknown';
        const nowMs = Date.now();
        const attemptState = loginAttempts.get(loginKey);
        if (attemptState && attemptState.lockedUntil > nowMs) {
          sendJson(res, 429, { error: 'Too many failed attempts. Try again later.' });
          return;
        }
        if (!db.user) {
          sendJson(res, 400, { error: 'PIN not configured' });
          return;
        }
        const candidate = hashPin(pin, db.user.salt);
        const stored = db.user.pinHash;
        const isMatch = crypto.timingSafeEqual(Buffer.from(candidate, 'hex'), Buffer.from(stored, 'hex'));
        if (!isMatch) {
          const fails = attemptState && attemptState.lockedUntil <= nowMs ? attemptState.fails + 1 : 1;
          const lockedUntil = fails >= MAX_LOGIN_ATTEMPTS ? nowMs + LOGIN_LOCK_WINDOW_MS : 0;
          loginAttempts.set(loginKey, { fails, lockedUntil });
          sendJson(res, 401, { error: 'Invalid PIN' });
          return;
        }
        loginAttempts.delete(loginKey);
        const token = crypto.randomBytes(24).toString('hex');
        const expiresAt = Date.now() + SESSION_DURATION_MS;
        db.sessions = db.sessions.filter((s) => s.expiresAt > Date.now());
        db.sessions.push({ token, userId: 1, expiresAt });
        saveDb(dataPath, db);
        sendJson(res, 200, { token, expiresAt });
        return;
      }

      if (url.pathname.startsWith('/api/')) {
        const auth = req.headers.authorization || '';
        const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
        const session = db.sessions.find((s) => s.token === token && s.expiresAt > Date.now());
        if (!session) {
          sendJson(res, 401, { error: 'Unauthorized' });
          return;
        }
      }

      if (req.method === 'POST' && url.pathname === '/api/documents') {
        const body = await readJsonBody(req);
        const required = ['name', 'category', 'fileName', 'fileContent', 'mimeType'];
        for (const key of required) {
          if (!body[key]) {
            sendJson(res, 400, { error: `Missing field: ${key}` });
            return;
          }
        }
        const isPermanent = Boolean(body.isPermanent);
        if (!isPermanent && !body.expiryDate) {
          sendJson(res, 400, { error: 'Expiry date is required for expirable documents' });
          return;
        }
        const docId = db.counters.doc++;
        const versionId = db.counters.version++;
        const now = new Date().toISOString();
        const doc = {
          id: docId,
          name: String(body.name).trim(),
          category: String(body.category).trim(),
          isPermanent,
          expiryDate: isPermanent ? null : String(body.expiryDate),
          createdAt: now,
          updatedAt: now,
          latestVersion: 1
        };
        const version = {
          id: versionId,
          documentId: docId,
          versionNumber: 1,
          fileName: String(body.fileName),
          fileContent: String(body.fileContent),
          mimeType: String(body.mimeType),
          notes: body.notes ? String(body.notes) : '',
          createdAt: now
        };
        db.documents.push(doc);
        db.versions.push(version);
        saveDb(dataPath, db);
        sendJson(res, 201, { document: sanitizeDocument(doc), version: { ...version, fileContent: undefined } });
        return;
      }

      if (req.method === 'POST' && /^\/api\/documents\/\d+\/versions$/.test(url.pathname)) {
        const id = Number(url.pathname.split('/')[3]);
        const doc = db.documents.find((d) => d.id === id);
        if (!doc) {
          sendJson(res, 404, { error: 'Document not found' });
          return;
        }
        const body = await readJsonBody(req);
        const required = ['fileName', 'fileContent', 'mimeType'];
        for (const key of required) {
          if (!body[key]) {
            sendJson(res, 400, { error: `Missing field: ${key}` });
            return;
          }
        }
        const now = new Date().toISOString();
        const nextVersion = doc.latestVersion + 1;
        const version = {
          id: db.counters.version++,
          documentId: id,
          versionNumber: nextVersion,
          fileName: String(body.fileName),
          fileContent: String(body.fileContent),
          mimeType: String(body.mimeType),
          notes: body.notes ? String(body.notes) : '',
          createdAt: now
        };
        doc.latestVersion = nextVersion;
        doc.updatedAt = now;
        db.versions.push(version);
        saveDb(dataPath, db);
        sendJson(res, 201, { version: { ...version, fileContent: undefined } });
        return;
      }

      if (req.method === 'GET' && url.pathname === '/api/documents') {
        const query = (url.searchParams.get('query') || '').toLowerCase();
        const category = url.searchParams.get('category') || '';
        const status = url.searchParams.get('status') || '';
        let docs = db.documents.slice();
        if (query) {
          docs = docs.filter((d) => d.name.toLowerCase().includes(query) || d.category.toLowerCase().includes(query));
        }
        if (category) {
          docs = docs.filter((d) => d.category.toLowerCase() === category.toLowerCase());
        }
        if (status) {
          docs = docs.filter((d) => {
            if (status === 'expiring') {
              if (d.isPermanent || !d.expiryDate) return false;
              const days = daysUntil(d.expiryDate);
              return days >= 0 && days <= db.settings.reminderDays;
            }
            return getStatus(d) === status;
          });
        }
        sendJson(res, 200, { documents: docs.map(sanitizeDocument) });
        return;
      }

      if (req.method === 'GET' && /^\/api\/documents\/\d+$/.test(url.pathname)) {
        const id = Number(url.pathname.split('/')[3]);
        const doc = db.documents.find((d) => d.id === id);
        if (!doc) {
          sendJson(res, 404, { error: 'Document not found' });
          return;
        }
        const versions = db.versions
          .filter((v) => v.documentId === id)
          .map((v) => ({ ...v, fileContent: undefined }))
          .sort((a, b) => b.versionNumber - a.versionNumber);
        sendJson(res, 200, { document: sanitizeDocument(doc), versions });
        return;
      }

      if (req.method === 'GET' && /^\/api\/documents\/\d+\/download\/\d+$/.test(url.pathname)) {
        const parts = url.pathname.split('/');
        const id = Number(parts[3]);
        const versionId = Number(parts[5]);
        const version = db.versions.find((v) => v.documentId === id && v.id === versionId);
        if (!version) {
          sendJson(res, 404, { error: 'Version not found' });
          return;
        }
        const buffer = Buffer.from(version.fileContent, 'base64');
        const safeFileName = version.fileName.replace(/[^a-zA-Z0-9_-]+/g, '_');
        res.writeHead(200, {
          'Content-Type': version.mimeType,
          'Content-Disposition': `attachment; filename="${safeFileName}"`
        });
        res.end(buffer);
        return;
      }

      if (req.method === 'GET' && url.pathname === '/api/reminders') {
        const days = Number(url.searchParams.get('days') || db.settings.reminderDays);
        const reminders = db.documents
          .filter((d) => !d.isPermanent && d.expiryDate)
          .map((d) => ({ document: sanitizeDocument(d), daysLeft: daysUntil(d.expiryDate) }))
          .filter((r) => r.daysLeft >= 0 && r.daysLeft <= days)
          .sort((a, b) => a.daysLeft - b.daysLeft);
        sendJson(res, 200, { reminders });
        return;
      }

      if (req.method === 'PUT' && url.pathname === '/api/settings/reminder-days') {
        const body = await readJsonBody(req);
        const days = Number(body.days);
        if (!Number.isInteger(days) || days < 1 || days > 365) {
          sendJson(res, 400, { error: 'days must be an integer between 1 and 365' });
          return;
        }
        db.settings.reminderDays = days;
        saveDb(dataPath, db);
        sendJson(res, 200, { reminderDays: days });
        return;
      }

      sendJson(res, 404, { error: 'Not found' });
    } catch (error) {
      sendJson(res, 400, { error: error.message });
    }
  });

  return server;
}

module.exports = { createServer, DEFAULT_DATA_PATH, STATIC_DIR };
