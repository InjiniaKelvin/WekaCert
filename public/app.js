const state = {
  token: localStorage.getItem('token') || '',
  selectedDocumentId: null,
  cacheKey: 'wekacert-documents-cache',
  searchTimer: null
};

const els = {
  pin: document.getElementById('pin'),
  setupPin: document.getElementById('setup-pin'),
  login: document.getElementById('login'),
  authMessage: document.getElementById('auth-message'),
  authCard: document.getElementById('auth-card'),
  uploadCard: document.getElementById('upload-card'),
  listCard: document.getElementById('list-card'),
  detailsCard: document.getElementById('details-card'),
  docName: document.getElementById('doc-name'),
  docCategory: document.getElementById('doc-category'),
  docPermanent: document.getElementById('doc-permanent'),
  docExpiry: document.getElementById('doc-expiry'),
  docNotes: document.getElementById('doc-notes'),
  docFile: document.getElementById('doc-file'),
  upload: document.getElementById('upload'),
  search: document.getElementById('search'),
  statusFilter: document.getElementById('status-filter'),
  refresh: document.getElementById('refresh'),
  docList: document.getElementById('doc-list'),
  docDetails: document.getElementById('doc-details'),
  verNotes: document.getElementById('ver-notes'),
  verFile: document.getElementById('ver-file'),
  addVersion: document.getElementById('add-version')
};

function setAuthenticated(authed) {
  els.uploadCard.classList.toggle('hidden', !authed);
  els.listCard.classList.toggle('hidden', !authed);
  els.detailsCard.classList.toggle('hidden', true);
}

async function api(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (state.token) headers.Authorization = `Bearer ${state.token}`;
  const response = await fetch(path, { ...options, headers });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(payload.error || 'Request failed');
  return payload;
}

function readFileAsBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(',')[1]);
    reader.onerror = () => reject(new Error('Unable to read file'));
    reader.readAsDataURL(file);
  });
}

async function setupPin() {
  try {
    await api('/api/auth/setup-pin', { method: 'POST', body: JSON.stringify({ pin: els.pin.value }) });
    els.authMessage.textContent = 'PIN setup complete. Login now.';
  } catch (error) {
    els.authMessage.textContent = error.message;
  }
}

async function login() {
  try {
    const data = await api('/api/auth/login', { method: 'POST', body: JSON.stringify({ pin: els.pin.value }) });
    state.token = data.token;
    localStorage.setItem('token', state.token);
    els.authMessage.textContent = 'Logged in.';
    setAuthenticated(true);
    await loadDocuments();
  } catch (error) {
    els.authMessage.textContent = error.message;
  }
}

async function uploadDocument() {
  const file = els.docFile.files[0];
  if (!file) return alert('Please select a file to upload');
  const body = {
    name: els.docName.value,
    category: els.docCategory.value,
    isPermanent: els.docPermanent.checked,
    expiryDate: els.docPermanent.checked ? null : els.docExpiry.value,
    notes: els.docNotes.value,
    fileName: file.name,
    mimeType: file.type || 'application/octet-stream',
    fileContent: await readFileAsBase64(file)
  };
  await api('/api/documents', { method: 'POST', body: JSON.stringify(body) });
  els.docName.value = '';
  els.docNotes.value = '';
  els.docFile.value = '';
  await loadDocuments();
}

function renderList(documents) {
  els.docList.innerHTML = '';
  for (const doc of documents) {
    const li = document.createElement('li');
    li.textContent = `${doc.name} • ${doc.category} • ${doc.isPermanent ? 'Permanent' : doc.expiryDate || 'No expiry'}`;
    li.onclick = () => loadDocument(doc.id);
    els.docList.appendChild(li);
  }
}

async function loadDocuments() {
  const params = new URLSearchParams();
  if (els.search.value.trim()) params.set('query', els.search.value.trim());
  if (els.statusFilter.value) params.set('status', els.statusFilter.value);

  try {
    const data = await api(`/api/documents?${params.toString()}`);
    localStorage.setItem(state.cacheKey, JSON.stringify(data.documents));
    renderList(data.documents);
  } catch (error) {
    const cache = localStorage.getItem(state.cacheKey);
    if (cache) {
      renderList(JSON.parse(cache));
    } else {
      els.docList.innerHTML = `<li>${error.message}</li>`;
    }
  }
}

async function loadDocument(id) {
  state.selectedDocumentId = id;
  const data = await api(`/api/documents/${id}`);
  els.detailsCard.classList.remove('hidden');
  els.docDetails.textContent = JSON.stringify(data, null, 2);
}

async function addVersion() {
  if (!state.selectedDocumentId) return alert('Select a document first');
  const file = els.verFile.files[0];
  if (!file) return alert('Please select a file for the new version');

  await api(`/api/documents/${state.selectedDocumentId}/versions`, {
    method: 'POST',
    body: JSON.stringify({
      fileName: file.name,
      mimeType: file.type || 'application/octet-stream',
      fileContent: await readFileAsBase64(file),
      notes: els.verNotes.value
    })
  });
  els.verFile.value = '';
  els.verNotes.value = '';
  await loadDocument(state.selectedDocumentId);
  await loadDocuments();
}

els.setupPin.onclick = setupPin;
els.login.onclick = login;
els.upload.onclick = () => uploadDocument().catch((e) => alert(e.message));
els.refresh.onclick = () => loadDocuments();
els.search.oninput = () => {
  clearTimeout(state.searchTimer);
  state.searchTimer = setTimeout(() => loadDocuments(), 300);
};
els.statusFilter.onchange = () => loadDocuments();
els.addVersion.onclick = () => addVersion().catch((e) => alert(e.message));
els.docPermanent.onchange = () => {
  els.docExpiry.disabled = els.docPermanent.checked;
  if (els.docPermanent.checked) els.docExpiry.value = '';
};

if (state.token) {
  setAuthenticated(true);
  loadDocuments();
}
