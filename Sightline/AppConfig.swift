import Foundation

/// Build-level feature flags.
enum AppConfig {
    /// v1 on the App Store ships with sample data only: there is no public
    /// backend yet, so sign-in and bank linking would hit dead endpoints in
    /// review. Flip to true once the proxy is deployed to public HTTPS with a
    /// production Basiq key — the full flow (auth, consent, live snapshots)
    /// is already built and simply reappears.
    static let bankLinkingEnabled = false
}
