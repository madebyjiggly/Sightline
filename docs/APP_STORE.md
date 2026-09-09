# App Store readiness

What's already done in the codebase, and the steps that need **you** (they require
an Apple Developer account, signing, or the App Store Connect website).

## ✅ Done (in the repo)
- **App icon** — 1024×1024, opaque (no alpha), wired via `ASSETCATALOG_COMPILER_APPICON_NAME`
  (`Sightline/Assets.xcassets/AppIcon.appiconset/AppIcon.png`).
- **Privacy manifest** — `Sightline/PrivacyInfo.xcprivacy` (no tracking, no SDK data
  collection, UserDefaults required-reason `CA92.1`).
- **Portrait-only**, iOS 17+ deployment target, launch screen configured (`Info.plist`).
- **Marketing version 1.0 / build 1** (bump per release in the target build settings).
- Builds clean for the simulator in CI.

## ⏳ Needs you (skipped — require your account/credentials)
1. **Apple Developer Program** — enrol (~A$149/yr) at <https://developer.apple.com/programs/>.
2. **Signing** — in Xcode → target *Signing & Capabilities*: pick your Team, set a unique
   **Bundle ID** you own (currently `com.sightline.budget` — change if taken), enable
   automatic signing. Add the **Background Modes → Background fetch** capability (the code
   + Info.plist already expect it) and **Push? no** (we use local notifications only).
3. **App Store Connect** — create the app record at <https://appstoreconnect.apple.com>:
   name, subtitle, category (Finance), **privacy policy URL** (required) and **support URL**.
   Drafts are ready in [`PRIVACY.md`](PRIVACY.md) and [`SUPPORT.md`](SUPPORT.md) — fill in your
   contact email, then host them (easiest: enable **GitHub Pages** for `/docs` in the repo
   settings, giving `https://madebyjiggly.github.io/Sightline/PRIVACY`).
4. **Privacy nutrition label** — answer the questionnaire: you collect *email* (account) and
   *financial info* (budgets/transactions via your server), used for app functionality, not
   tracking. Keep it consistent with `PrivacyInfo.xcprivacy`.
5. **Screenshots** — ready-to-upload 6.9" (1320×2868) shots are in `docs/appstore/`
   (Home, Calendar month view, Goals, Cards, Settings — light mode, 9:41 status bar). App Store Connect also asks for a 6.5" set — generate
   those from an iPhone 15 Plus / 14 Plus simulator the same way if needed.
6. **Backend for production** — the Node proxy in `server/` must be deployed to a public
   HTTPS host (not localhost), with a **production** Basiq key and CDR accreditation via
   Basiq. Point the app's proxy URL at it.
7. **Archive & upload** — Xcode → *Product → Archive* → *Distribute App → App Store Connect*
   (needs signing from step 2). Then submit for review in App Store Connect.

## Suggested listing copy (draft — tweak freely)
- **Name:** Sightline — Budget Tracker
- **Subtitle:** See your money clearly
- **Keywords:** budget,spending,money,finance,tracker,savings,bank,expenses,budgeting,AUD
- **Promotional text:** Track spending against your budgets, set goals, and get alerted
  before a category goes over.
- **Description:**
  > Sightline gives you a clear line of sight on your money. Set a monthly budget for each
  > category, then watch your spending update against it in real time — green when you're
  > under, red when you're over. Connect your bank securely through Basiq (open banking) or
  > explore with sample data first.
  >
  > • Budgets with instant under/over status
  > • Your own categories with automatic transaction matching
  > • Day / week / month calendar with a spending heatmap
  > • Savings goals with a guided planner
  > • Over-budget alerts — all on-device
  > • Light & dark themes
  >
  > Your bank login is never seen by Sightline — you sign in on your bank's own page.

## Notes
- The app runs on sample data with no backend, so it's demoable without any of the above.
- Real bank data additionally needs Basiq **production** access + the in-app Basiq Connect
  consent flow (already built).
