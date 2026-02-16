const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { createServer } = require('../src/server');

async function startTestServer() {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'wekacert-test-'));
  const dataPath = path.join(tmpDir, 'db.json');
  const server = createServer({ dataPath, staticDir: path.join(__dirname, '..', 'public') });

  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://127.0.0.1:${port}`;

  return {
    baseUrl,
    close: async () => {
      await new Promise((resolve) => server.close(resolve));
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  };
}

async function api(baseUrl, pathName, options = {}, token = '') {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (token) headers.Authorization = `Bearer ${token}`;
  const response = await fetch(`${baseUrl}${pathName}`, { ...options, headers });
  const body = await response.json();
  return { status: response.status, body };
}

test('PIN setup, login, upload, list, version, reminders work', async () => {
  const app = await startTestServer();

  try {
    let res = await api(app.baseUrl, '/api/auth/setup-pin', {
      method: 'POST',
      body: JSON.stringify({ pin: '1234' })
    });
    assert.equal(res.status, 201);

    res = await api(app.baseUrl, '/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ pin: '1234' })
    });
    assert.equal(res.status, 200);
    const token = res.body.token;

    const expiry = new Date(Date.now() + 5 * 86400000).toISOString().slice(0, 10);
    const fileContent = Buffer.from('hello world').toString('base64');

    res = await api(app.baseUrl, '/api/documents', {
      method: 'POST',
      body: JSON.stringify({
        name: 'National ID',
        category: 'ID',
        isPermanent: false,
        expiryDate: expiry,
        notes: 'primary copy',
        fileName: 'id.txt',
        mimeType: 'text/plain',
        fileContent
      })
    }, token);
    assert.equal(res.status, 201);
    const docId = res.body.document.id;

    res = await api(app.baseUrl, '/api/documents?query=national', {}, token);
    assert.equal(res.status, 200);
    assert.equal(res.body.documents.length, 1);

    res = await api(app.baseUrl, `/api/documents/${docId}/versions`, {
      method: 'POST',
      body: JSON.stringify({
        fileName: 'id-v2.txt',
        mimeType: 'text/plain',
        fileContent,
        notes: 'renewed'
      })
    }, token);
    assert.equal(res.status, 201);

    res = await api(app.baseUrl, `/api/documents/${docId}`, {}, token);
    assert.equal(res.status, 200);
    assert.equal(res.body.versions.length, 2);

    res = await api(app.baseUrl, '/api/reminders?days=30', {}, token);
    assert.equal(res.status, 200);
    assert.equal(res.body.reminders.length, 1);
  } finally {
    await app.close();
  }
});
