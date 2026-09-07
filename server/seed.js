// One-time sandbox setup: creates a Basiq test user, connects the test bank,
// and prints the user id to paste into your .env as BASIQ_USER_ID.
import 'dotenv/config';
import { Basiq } from './basiq.js';

async function main() {
  console.log('Creating a Basiq sandbox user…');
  const user = await Basiq.createUser(
    process.env.SEED_EMAIL || 'demo+sightline@example.com',
    process.env.SEED_MOBILE || '+61410000000'
  );
  console.log('  user id:', user.id);

  console.log('Connecting the sandbox test bank (AU00000)…');
  const job = await Basiq.connectSandbox(user.id);
  console.log('  connection job started:', job.id || '(see Basiq dashboard)');

  console.log('\nAdd this to server/.env:');
  console.log(`BASIQ_USER_ID=${user.id}`);
  console.log('\nGive the connection ~30s to finish fetching, then start the proxy: npm start');
}

main().catch((e) => { console.error(e); process.exit(1); });
