// Sightline proxy — the iOS app talks ONLY to this server, which talks to Basiq.
// This keeps the Basiq API key off the device.
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { Basiq, clientToken, mapAccount, mapTransaction } from './basiq.js';
import * as auth from './auth.js';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;

// Health check
app.get('/', (_req, res) => res.json({ ok: true, service: 'sightline-proxy' }));

// ---- Auth -----------------------------------------------------------------
app.post('/auth/register', (req, res) => {
  try { res.json(auth.register(req.body?.email, req.body?.password)); }
  catch (err) { res.status(400).json({ error: String(err.message || err) }); }
});
app.post('/auth/login', (req, res) => {
  try { res.json(auth.login(req.body?.email, req.body?.password)); }
  catch (err) { res.status(401).json({ error: String(err.message || err) }); }
});

// Bearer-token middleware for the protected /me routes.
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const userId = auth.userIdForToken(token);
  if (!userId) return res.status(401).json({ error: 'Sign in to use live data.' });
  req.userId = userId;
  next();
}

// Each signed-in user gets their own Basiq user, created on demand.
async function ensureBasiqUserFor(appUserId) {
  const u = auth.userById(appUserId);
  if (u?.basiqUserId) return u.basiqUserId;
  const created = await Basiq.createUser(u.email, process.env.SEED_MOBILE || '+61410000000');
  auth.setBasiqUserId(appUserId, created.id);
  console.log('Created Basiq user for', u.email, '→', created.id);
  return created.id;
}

// Start the in-app bank-consent flow: returns the hosted Basiq Connect URL the
// app opens. The user picks their bank and logs in on the bank's own page.
app.get('/me/connect-token', requireAuth, async (req, res) => {
  try {
    const uid = await ensureBasiqUserFor(req.userId);
    const token = await clientToken(uid);
    res.json({
      token,
      consentUrl: `https://consent.basiq.io/home?token=${token}&action=connect`,
    });
  } catch (err) {
    console.error(err);
    res.status(502).json({ error: String(err.message || err) });
  }
});

// The one data endpoint the app calls. The app POSTs its category rules
// ({ categories: [{ key, keywords }] }) so we can tag each transaction onto the
// user's own categories — including custom ones — before returning them.
app.post('/me/snapshot', requireAuth, async (req, res) => {
  try {
    const rules = Array.isArray(req.body?.categories) ? req.body.categories : [];
    const basiqUserId = await ensureBasiqUserFor(req.userId);
    const [accountsRes, txnRes] = await Promise.all([
      Basiq.getAccounts(basiqUserId),
      Basiq.getTransactions(basiqUserId),
    ]);
    const accounts = (accountsRes.data || []).map(mapAccount);
    const transactions = (txnRes.data || [])
      .filter((t) => Number(t.amount) < 0)   // spending only (debits)
      .map((t) => mapTransaction(t, rules))
      .filter((t) => t.date);
    res.json({ accounts, transactions });
  } catch (err) {
    console.error(err);
    res.status(502).json({ error: String(err.message || err) });
  }
});

app.listen(PORT, () => {
  console.log(`Sightline proxy listening on http://localhost:${PORT}`);
  console.log('Point the iOS app BackendConfig.baseURL here, then set AppStore.useLiveData = true.');
});
