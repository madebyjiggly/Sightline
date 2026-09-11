# Deploying the Sightline proxy

The Node server in [`server/`](../server) is the only backend Sightline needs. It holds
your Basiq API key, handles user accounts, and returns normalized account + transaction
data to the app. To enable live bank data in the app, this server must run on a **public
HTTPS host** — the app on a real iPhone can't reach `localhost`.

Recommended host: **Railway** (simplest for this repo's layout). Fly.io and Render work
the same way; their differences are noted at the end.

---

## Before you start

- [ ] A [Basiq](https://dashboard.basiq.io) account and API key.
      Sandbox keys only reach Basiq's fake test banks — fine for testing the deployed
      proxy end-to-end. **Real** bank data needs a production key: apply under
      *Settings → Access* in the Basiq dashboard (they handle CDR compliance; approval
      is an application process, not a code change).
- [ ] The Railway CLI (`brew install railway`) or just the railway.com web dashboard.

## 1. Create the service

From the repo root:

```bash
cd server && railway init
```

Accept the prompts (new project, name it `sightline-proxy`). Then deploy:

```bash
railway up
```

Railway detects the Node app and runs `npm start` automatically. In the dashboard,
open the service → **Settings → Networking → Generate Domain**. You'll get a URL like
`https://sightline-proxy-production.up.railway.app` — that's your proxy URL, already
HTTPS.

> Deploying from the dashboard instead: "New Project → Deploy from GitHub repo", pick
> `madebyjiggly/Sightline`, and set the **root directory** to `server/`.

## 2. Set the environment variables

Dashboard → your service → **Variables** (never commit these):

| Variable | Value |
| --- | --- |
| `BASIQ_API_KEY` | your Basiq key (sandbox to test, production to go live) |
| `BASIQ_BASE_URL` | `https://au-api.basiq.io` (the default; set only to override) |

Notes:

- `PORT` is injected by Railway automatically; the server reads it.
- `BASIQ_USER_ID` / `BASIQ_TEST_*` are only used by the legacy `npm run seed` sandbox
  path. The app's real flow creates a Basiq user per signed-in account, so you can
  leave them unset in production.

## 3. Give user accounts a disk that survives deploys

The proxy stores registered users in a JSON file at `server/.data/users.json`
(`server/auth.js`). Hosting filesystems are **ephemeral** — every redeploy wipes them —
so attach a persistent volume:

- Railway: service → right-click canvas → **Volume**, mount path `/app/.data`.

Without this, every deploy signs all users out and deletes their accounts. (A real
database is the eventual fix; the volume is fine at this scale.)

## 4. Smoke-test the deployment

```bash
curl https://YOUR-PROXY-URL/
```

Expect `{"ok":true,"service":"sightline-proxy"}`. Then register a test user and pull a snapshot:

```bash
curl -s -X POST https://YOUR-PROXY-URL/auth/register -H 'content-type: application/json' -d '{"email":"test@example.com","password":"test-password-123"}'
```

Use the returned token:

```bash
curl -s -X POST https://YOUR-PROXY-URL/me/snapshot -H "authorization: Bearer THE_TOKEN" -H 'content-type: application/json' -d '{"rules":[]}'
```

With a sandbox key you'll get Basiq's test-bank data back once a bank is connected via
the consent flow; before that, an empty/502 response with a clear error is normal.

## 5. Point the app at it and re-enable bank linking

1. In [`Sightline/Services/BasiqService.swift`](../Sightline/Services/BasiqService.swift),
   change `BackendConfig.defaultURLString` from `http://localhost:4000` to your proxy URL.
2. In [`Sightline/AppConfig.swift`](../Sightline/AppConfig.swift), flip
   `bankLinkingEnabled` to `true` — sign-in, Bank connection and the Basiq consent flow
   all reappear.
3. Optional cleanup: remove `NSAllowsLocalNetworking` from `Info.plist` (it existed only
   for the simulator to reach localhost).
4. Test on the simulator against the **deployed** URL: sign in, Connect a bank
   (sandbox: test bank `AU00000`, login `gavinBelson`, password `hello`), pull to
   refresh, watch the badge flip to **Live**.
5. Bump the version to 1.1, update the App Store description (drop "coming soon"),
   refresh the privacy label (with accounts + bank data it becomes *email + financial
   info, linked to you, for app functionality*), archive and submit.

## Costs and alternatives

- **Railway**: ~US$5/mo hobby plan covers this comfortably.
- **Fly.io**: `fly launch` inside `server/`, add a volume with `fly volumes create data`
  and mount it at `/app/.data`; secrets via `fly secrets set BASIQ_API_KEY=...`.
- **Render**: free web services **sleep** after idle (first request takes ~1 min — bad
  for background refresh) and free tier has no persistent disk. Use the paid tier if
  you pick Render.

## Production hardening (before real users)

- Swap the JSON user store for a real database (Postgres on the same host).
- Add rate limiting on `/auth/*` (e.g. `express-rate-limit`).
- Set a `CORS` allowlist if you ever add a web client; the iOS app doesn't need CORS.
- Keep the Basiq key only in host secrets — it never ships in the app, which is the
  whole point of this proxy.
