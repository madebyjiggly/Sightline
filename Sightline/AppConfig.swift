import Foundation

/// Build-level feature flags.
enum AppConfig {
    /// v1.1+: live bank linking is ON — sign-in, the Basiq consent flow and
    /// live snapshots all talk to the deployed proxy (see BackendConfig).
    /// v1.0 shipped with this off because no public backend existed yet.
    static let bankLinkingEnabled = true
}
