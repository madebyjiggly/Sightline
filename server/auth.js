// Minimal but real email/password auth: bcrypt-hashed passwords, random bearer
// tokens, persisted to a JSON file. Each app user maps to their own Basiq user.
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { fileURLToPath } from 'url';

const dir = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(dir, '.data');
const FILE = path.join(DATA_DIR, 'users.json');

function load() {
  try { return JSON.parse(fs.readFileSync(FILE, 'utf8')); }
  catch { return { users: {}, tokens: {} }; }
}
function persist(db) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(FILE, JSON.stringify(db, null, 2));
}

const db = load(); // { users: { [email]: {id,email,passwordHash,basiqUserId} }, tokens: { [token]: userId } }

function issueToken(userId) {
  const token = crypto.randomBytes(24).toString('hex');
  db.tokens[token] = userId;
  return token;
}

export function register(email, password) {
  email = String(email || '').trim().toLowerCase();
  if (!email.includes('@')) throw new Error('Enter a valid email address.');
  if (!password || password.length < 6) throw new Error('Password must be at least 6 characters.');
  if (db.users[email]) throw new Error('An account with that email already exists.');
  const id = 'u_' + crypto.randomUUID();
  db.users[email] = { id, email, passwordHash: bcrypt.hashSync(password, 10), basiqUserId: null };
  const token = issueToken(id);
  persist(db);
  return { token, email, userId: id };
}

export function login(email, password) {
  email = String(email || '').trim().toLowerCase();
  const u = db.users[email];
  if (!u || !bcrypt.compareSync(String(password || ''), u.passwordHash)) {
    throw new Error('Wrong email or password.');
  }
  const token = issueToken(u.id);
  persist(db);
  return { token, email: u.email, userId: u.id };
}

export function userIdForToken(token) {
  return db.tokens[token] || null;
}
export function userById(id) {
  return Object.values(db.users).find((u) => u.id === id) || null;
}
export function setBasiqUserId(id, basiqUserId) {
  const u = userById(id);
  if (u) { u.basiqUserId = basiqUserId; persist(db); }
}
