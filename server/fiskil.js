// Fiskil client (Australian CDR open banking). Same role as basiq.js: the
// client credentials live only here, on the server — never in the iOS app.
// Docs: https://docs.fiskil.com  (Data API: /v1/token, /v1/end-users,
// /v1/auth/session, /v1/banking/{accounts,balances,transactions})
import 'dotenv/config';
import { categorize } from './basiq.js';

const BASE = process.env.FISKIL_BASE_URL || 'https://api.fiskil.com';
const CLIENT_ID = process.env.FISKIL_CLIENT_ID;
const CLIENT_SECRET = process.env.FISKIL_CLIENT_SECRET;

// Where Fiskil's hosted consent UI sends the user when they cancel or finish.
// The app watches for the Safari sheet closing, so any page works here.
const RETURN_URI = process.env.FISKIL_RETURN_URI || 'https://madebyjiggly.github.io/Sightline/';

let cachedToken = null;
let tokenExpiry = 0;

export const isConfigured = () => Boolean(CLIENT_ID && CLIENT_SECRET);

/** Exchange client credentials for a short-lived access token (cached). */
async function token() {
  if (!isConfigured()) throw new Error('FISKIL_CLIENT_ID / FISKIL_CLIENT_SECRET are not set.');
  const now = Date.now();
  if (cachedToken && now < tokenExpiry) return cachedToken;
  const res = await fetch(`${BASE}/v1/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET }),
  });
  if (!res.ok) throw new Error(`Fiskil token failed: ${res.status} ${await res.text()}`);
  const json = await res.json();
  cachedToken = json.token || json.access_token;
  // expires_in may be absent; refresh conservatively every 10 minutes.
  const ttl = Number(json.expires_in) > 60 ? Number(json.expires_in) - 60 : 600;
  tokenExpiry = now + ttl * 1000;
  return cachedToken;
}

async function api(path, { method = 'GET', body, query } = {}) {
  const t = await token();
  const qs = query ? `?${new URLSearchParams(query)}` : '';
  const res = await fetch(`${BASE}${path}${qs}`, {
    method,
    headers: {
      Authorization: `Bearer ${t}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`Fiskil ${method} ${path} failed: ${res.status} ${await res.text()}`);
  return res.status === 204 ? null : res.json();
}

// ---- End users & consent ---------------------------------------------------

/** Create a Fiskil end user for an app account; returns its id. */
export async function createEndUser(email) {
  const u = await api('/v1/end-users', { method: 'POST', body: { email, name: email.split('@')[0] } });
  return u.end_user_id || u.id;
}

/** Start the hosted consent flow; returns the URL the app opens in Safari. */
export async function consentUrl(endUserId) {
  const s = await api('/v1/auth/session', {
    method: 'POST',
    body: { end_user_id: endUserId, cancel_uri: RETURN_URI, redirect_uri: RETURN_URI },
  });
  if (!s.auth_url) throw new Error('Fiskil did not return an auth_url.');
  return s.auth_url;
}

// ---- Data -------------------------------------------------------------------

/** Follow cursor pagination (links.next) up to a sane page cap. */
async function listAll(path, key, endUserId, extra = {}) {
  const out = [];
  let query = { end_user_id: endUserId, 'page[size]': '500', ...extra };
  for (let page = 0; page < 10; page++) {
    const r = await api(path, { query });
    out.push(...(r?.[key] || []));
    const next = r?.links?.next;
    if (!next) break;
    const after = new URL(next, BASE).searchParams.get('page[after]');
    if (!after) break;
    query = { ...query, 'page[after]': after };
  }
  return out;
}

const num = (v) => (v === undefined || v === null || v === '' ? NaN : Number(v));

// Map a CDR-style account + its balance onto the app's Account shape.
function mapAccount(a, bal) {
  const category = String(a.product_category || a.productCategory || '').toUpperCase();
  // CDR files everyday and savings accounts under one category
  // (TRANS_AND_SAVINGS_ACCOUNTS), so tell them apart by the account's name.
  const label = `${a.nickname || ''} ${a.display_name || ''} ${a.product_name || ''}`.toLowerCase();
  const kind = category.includes('CRED') ? 'credit'
    : (category.includes('TERM_DEPOSIT') || /saver|savings|goal|bonus|high interest/.test(label)) ? 'savings'
    : 'debit';
  const current = num(bal?.current_balance ?? bal?.currentBalance ?? a.current_balance);
  const available = num(bal?.available_balance ?? bal?.availableBalance);
  const balance = Number.isFinite(current) ? current : (Number.isFinite(available) ? available : 0);
  const masked = String(a.masked_number || a.maskedNumber || a.account_number || '')
    .replace(/\s+/g, '').slice(-4);

  const out = {
    nickname: a.nickname || a.display_name || a.displayName || a.product_name || 'Account',
    kind,
    network: a.institution_name || a.institution?.name || a.brand || 'Bank',
    maskedNumber: masked ? `•••• ${masked}` : '••••',
  };
  if (kind === 'credit') {
    out.owing = Math.abs(Math.min(0, balance));
    const limit = num(bal?.credit_limit ?? bal?.creditLimit ?? bal?.amortised_limit);
    out.limit = Number.isFinite(limit) ? Math.abs(limit) : 0;
  } else {
    out.balance = balance;
  }
  return out;
}

// Map a CDR-style transaction onto the app's Txn shape (spending only).
function mapTransaction(t, rules) {
  const desc = t.description || t.merchant_name || t.reference || '';
  const date = String(
    t.posting_date_time || t.execution_date_time || t.value_date_time || t.posted_at || t.date || ''
  ).slice(0, 10);
  return {
    name: (t.merchant_name || desc.split('  ')[0] || 'Transaction').slice(0, 40),
    key: categorize(`${t.merchant_name || ''} ${desc}`, rules),
    amount: Math.abs(num(t.amount) || 0),
    date,
  };
}

/** Accounts + last-90-days spending for one end user, in the app's shape. */
export async function snapshot(endUserId, rules) {
  const from = new Date(Date.now() - 90 * 24 * 3600 * 1000).toISOString();
  const [accounts, balances, txns] = await Promise.all([
    listAll('/v1/banking/accounts', 'accounts', endUserId),
    listAll('/v1/banking/balances', 'balances', endUserId),
    listAll('/v1/banking/transactions', 'transactions', endUserId, { from }),
  ]);
  const balById = Object.fromEntries(balances.map((b) => [b.account_id || b.accountId, b]));
  return {
    accounts: accounts.map((a) => mapAccount(a, balById[a.account_id || a.accountId])),
    transactions: txns
      .filter((t) => num(t.amount) < 0)          // debits are negative in CDR
      .map((t) => mapTransaction(t, rules))
      .filter((t) => t.date),
  };
}

/** Raw first records, for verifying field names against the live sandbox. */
export async function debugShapes(endUserId) {
  const pick = async (p, k) => (await api(p, { query: { end_user_id: endUserId, 'page[size]': '1' } }))?.[k]?.[0] ?? null;
  return {
    account: await pick('/v1/banking/accounts', 'accounts'),
    balance: await pick('/v1/banking/balances', 'balances'),
    transaction: await pick('/v1/banking/transactions', 'transactions'),
  };
}
