// Thin Basiq API client. The API KEY (server credential) lives only here, on the
// server — never in the iOS app. Docs: https://api.basiq.io/reference
import 'dotenv/config';

const BASE = process.env.BASIQ_BASE_URL || 'https://au-api.basiq.io';
const API_KEY = process.env.BASIQ_API_KEY;
const VERSION = '3.0';

let cachedToken = null;
let tokenExpiry = 0;

/** Exchange the API key for a short-lived SERVER_ACCESS token (cached). */
export async function serverToken() {
  if (!API_KEY) throw new Error('BASIQ_API_KEY is not set. Copy .env.example to .env and add your sandbox key.');
  const now = Date.now();
  if (cachedToken && now < tokenExpiry) return cachedToken;

  const res = await fetch(`${BASE}/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${API_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      'basiq-version': VERSION,
    },
    body: 'scope=SERVER_ACCESS',
  });
  if (!res.ok) throw new Error(`Basiq token failed: ${res.status} ${await res.text()}`);
  const json = await res.json();
  cachedToken = json.access_token;
  tokenExpiry = now + (json.expires_in - 30) * 1000;
  return cachedToken;
}

/** Mint a CLIENT_ACCESS token scoped to one user, for the in-app consent UI. */
export async function clientToken(userId) {
  if (!API_KEY) throw new Error('BASIQ_API_KEY is not set.');
  const res = await fetch(`${BASE}/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${API_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
      'basiq-version': VERSION,
    },
    body: `scope=CLIENT_ACCESS&userId=${encodeURIComponent(userId)}`,
  });
  if (!res.ok) throw new Error(`Basiq client token failed: ${res.status} ${await res.text()}`);
  const json = await res.json();
  return json.access_token;
}

async function api(path, { method = 'GET', body } = {}) {
  const token = await serverToken();
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'basiq-version': VERSION,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`Basiq ${method} ${path} failed: ${res.status} ${await res.text()}`);
  return res.status === 204 ? null : res.json();
}

export const Basiq = {
  createUser: (email, mobile) => api('/users', { method: 'POST', body: { email, mobile } }),
  getAccounts: (userId) => api(`/users/${userId}/accounts`),
  getTransactions: (userId, limit = 500) => api(`/users/${userId}/transactions?limit=${limit}`),
  /** Create a connection to a sandbox test bank (institution AU00000). */
  connectSandbox: (userId) => api(`/users/${userId}/connections`, {
    method: 'POST',
    body: {
      loginId: process.env.BASIQ_TEST_LOGIN || 'gavinBelson',
      password: process.env.BASIQ_TEST_PASSWORD || 'hello',
      institution: { id: process.env.BASIQ_TEST_INSTITUTION || 'AU00000' },
    },
  }),
};

// --- Map raw Basiq objects to the shape the iOS app expects ---------------

export function mapAccount(a) {
  // Basiq accounts have class.type: "transaction" | "savings" | "credit-card" | ...
  const type = a.class?.type || a.accountType || 'transaction';
  const kind = type.includes('credit') ? 'credit' : type.includes('savings') ? 'savings' : 'debit';
  const balance = Number(a.balance ?? a.availableFunds ?? 0);
  const masked = '•••• ' + String(a.accountNo || a.id || '0000').slice(-4);
  const out = {
    nickname: a.name || a.accountType || 'Account',
    kind,
    network: a.institution || a.bsb || 'Bank',
    maskedNumber: masked,
  };
  if (kind === 'credit') {
    out.owing = Math.abs(Math.min(0, balance));
    out.limit = Number(a.creditLimit ?? a.class?.product?.creditLimit ?? 0);
  } else {
    out.balance = balance;
  }
  return out;
}

// Assign a transaction to one of the user's categories by keyword match.
// `rules` come from the app: [{ key, keywords: [...] }]. First match wins;
// no match → "other". This is what lets custom categories capture spend.
export function categorize(description, rules) {
  const d = String(description || '').toLowerCase();
  for (const r of rules || []) {
    if ((r.keywords || []).some((k) => k && d.includes(String(k).toLowerCase()))) return r.key;
  }
  return 'other';
}

export function mapTransaction(t, rules) {
  const desc = t.description || t.subClass?.title || t.class || '';
  const amount = Math.abs(Number(t.amount || 0));
  const date = (t.postDate || t.transactionDate || '').slice(0, 10);
  return {
    name: (desc.split('  ')[0] || 'Transaction').slice(0, 40),
    key: categorize(desc, rules),
    amount,
    date,
  };
}
