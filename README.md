# Sightline — iOS Budgeting App (Australia)

[![CI](https://github.com/madebyjiggly/Sightline/actions/workflows/ci.yml/badge.svg)](https://github.com/madebyjiggly/Sightline/actions/workflows/ci.yml)

A native SwiftUI iPhone app that links your bank accounts via **Basiq** (Australia's
CDR / open-banking network), tracks live spending against budgets you set, and keeps
your financial goals in view.

It runs **right now on realistic AUD sample data** — no keys or backend required — and
switches to a **live Basiq sandbox** with a few steps.

---

## What's here

```
Sightline/
├── Sightline.xcodeproj          # open this in Xcode
├── Sightline/                   # the SwiftUI app
│   ├── SightlineApp.swift        # @main entry
│   ├── Theme.swift               # colours (light+dark), fonts, AUD formatting
│   ├── Models.swift              # domain models + budget-status logic
│   ├── SampleData.swift          # AUD sample data (default)
│   ├── Store/AppStore.swift      # app state (ObservableObject)
│   ├── Services/
│   │   ├── BankService.swift     # the data-source protocol + MockBankService
│   │   └── BasiqService.swift    # live Basiq client + snapshot aggregation
│   └── Views/                    # Home, Calendar, Goals, Cards, components, charts
└── server/                      # Node proxy that holds the Basiq API key
```

## Run the app (sample data)

1. Open `Sightline.xcodeproj` in Xcode 16+ (built with Xcode 26).
2. Pick an iPhone simulator and press ▶︎.

That's it — the app opens on sample data (the badge on Home reads **“Sample data”**).

Features: category budgets with live under/over status, a spending donut, a Day/Week/Month
calendar with a daily heatmap, financial goals with a guided planner, and multiple
accounts + a credit-card view. Tap any budget category to change its dollar amount.

## Go live with the Basiq sandbox

Basiq is the aggregator that connects to Australian banks. The **API key stays on the
server** — the app only ever talks to your proxy.

### 1. Get a Basiq key
- Sign up free at <https://dashboard.basiq.io> → **Developers → API Keys** → copy the key.

### 2. Start the proxy
```bash
cd server
cp .env.example .env          # then paste your BASIQ_API_KEY into .env
npm install
npm run seed                  # creates a sandbox user + connects the test bank
# paste the printed BASIQ_USER_ID into .env, wait ~30s, then:
npm start                     # → http://localhost:4000
```

### 3. Point the app at the proxy — all in-app now
On the Home screen, **tap the data-source badge** ("Sample data") to open **Bank connection**.
There you can set the Proxy URL (defaults to `http://localhost:4000`), tap **Test connection**,
and flip **Use live data (Basiq)** on. No rebuild or code edit needed — the choice is persisted.
(Localhost networking is already handled in `Info.plist` via `NSAllowsLocalNetworking`.)

When the proxy is running with a valid key, the Home badge reads **"Live · Basiq"** and the
numbers come from Basiq's sandbox bank.

## Architecture notes
- **`BankService` is the seam.** `MockBankService` and `BasiqBankService` both return a
  `FinanceSnapshot`; no View knows which is in use. Swapping Basiq for Plaid later means
  one new `BankService` implementation.
- **Budgets & goals are local user data** persisted with **SwiftData** (`Persistence.swift`:
  `BudgetItem`, `GoalItem`). They're seeded once from sample data, then survive launches;
  Basiq only ever supplies accounts + transactions (spending is never stored).
- **Security:** the app never sees bank credentials or the Basiq key; linking happens
  through the aggregator's secure consent flow. Follow CDR / Privacy Act obligations —
  operate under Basiq's accreditation.

## Next steps (not yet built)
- Detect the consent-flow completion automatically (deep-link callback) instead of on sheet dismiss.
- Move the user store off a JSON file to a real database, and add password reset.
- Manual "recategorise this transaction" (tap a txn → pick category, remember the merchant).

## Done
- ✅ SwiftData persistence for budgets & goals (survives app restarts; long-press a goal to delete).
- ✅ Custom categories — "New category" on Home (name, emoji, colour, budget); remove via a
  category's editor. Persisted alongside the built-in ones.
- ✅ Rename & reorder categories — tap a category to rename it (identity/spend link is preserved
  via a stable `key`); "Manage" on Home opens a drag-to-reorder / swipe-to-delete list.
- ✅ Over-budget alerts — local notifications (`Services/NotificationManager.swift`), toggled via
  the bell on Home. Fires once per category per month the moment spending passes its budget;
  runs entirely on-device (no server/APNs).
- ✅ Background refresh — `Services/BackgroundRefresh.swift` + `.backgroundTask(.appRefresh:)` in
  `SightlineApp`. On a real device the OS periodically wakes the app to pull fresh transactions
  and fire alerts while it's closed. Requires `Info.plist` (BGTaskSchedulerPermittedIdentifiers +
  UIBackgroundModes=fetch). Note: the iOS **Simulator** cannot run background tasks — `submit`
  returns BGTaskSchedulerErrorDomain Code=1 (unavailable) there; test wake-ups on a device via
  Xcode's "Simulate Background Fetch" or the LLDB `_simulateLaunchForTaskWithIdentifier`.
- ✅ In-app bank connection — tap the data-source badge on Home → **Bank connection**
  (`Views/BankConnection.swift`). Includes the **Basiq Connect consent flow**: "Connect a bank"
  asks the proxy for a CLIENT_ACCESS token (`server` `GET /users/:id/connect-token`) and opens
  Basiq's hosted consent UI in an in-app Safari view (`Views/SafariView.swift`); the user logs in
  on their bank's own page, and on return the app switches to live and reloads. Live/sample toggle
  + editable proxy URL + Test connection all here too.
- ✅ Light / Dark / System theme — `Services/ThemeManager.swift`, picker at Home → the appearance
  icon (`Views/AppearanceSettings.swift`); applied via `.preferredColorScheme` and persisted.
- ✅ Live transaction categorisation onto your categories — each category has editable **match
  keywords** (category creator + editor). The app POSTs its category rules to the proxy, which
  tags each live transaction onto the matching category (custom ones included; first match wins,
  unmatched → an "Other" row). Built-ins ship with sensible default keywords. Server logic:
  `categorize()` in `server/basiq.js`; app aggregation in `SnapshotBuilder` keyed by category.
- ✅ Real user auth — email/password with bcrypt-hashed passwords + bearer tokens on the proxy
  (`server/auth.js`, persisted to `server/.data/users.json`); the app stores only the session token
  in the Keychain (`Services/Keychain.swift`, `Services/AuthManager.swift`, `Views/AuthView.swift`).
  Live data & bank-connect require sign-in; each user gets their own Basiq user. Sign in / out from
  Bank connection. Data endpoints are now `/me/snapshot` and `/me/connect-token` (Bearer-protected).
