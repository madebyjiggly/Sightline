import SwiftUI

/// The single place for everything configurable: account, bank connection,
/// categories, alerts, appearance and about. Opened from the gear on Home.
struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var notifier: NotificationManager
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var showAuth = false

    private let privacyURL = URL(string: "https://madebyjiggly.github.io/Sightline/PRIVACY")!
    private let supportURL = URL(string: "https://madebyjiggly.github.io/Sightline/SUPPORT")!
    private let sourceURL  = URL(string: "https://github.com/madebyjiggly/Sightline")!

    var body: some View {
        NavigationStack {
            Screen(title: "Settings") {
                accountCard

                SectionHeader(title: "Money")
                SettingsGroup {
                    NavigationLink { BankConnectionContent() } label: {
                        SettingsRow(icon: "building.columns.fill", tint: Theme.accent,
                                    title: "Bank connection",
                                    value: store.isLive ? "Live · Basiq" : "Sample data")
                    }
                    SettingsDivider()
                    NavigationLink { ManageCategoriesContent() } label: {
                        SettingsRow(icon: "square.grid.2x2.fill", tint: Color(hex: "3E6BB0"),
                                    title: "Categories", value: "\(store.categories.count)")
                    }
                }

                SectionHeader(title: "App")
                SettingsGroup {
                    NavigationLink { AlertsSettingsContent() } label: {
                        SettingsRow(icon: "bell.fill", tint: Theme.warn,
                                    title: "Alerts", value: notifier.enabled ? "On" : "Off")
                    }
                    SettingsDivider()
                    NavigationLink { AppearanceContent() } label: {
                        SettingsRow(icon: "circle.lefthalf.filled", tint: Color(hex: "8A5BC7"),
                                    title: "Appearance", value: theme.mode.label)
                    }
                }

                SectionHeader(title: "About")
                SettingsGroup {
                    SettingsRow(icon: "info.circle.fill", tint: Theme.faint,
                                title: "Version", value: appVersion, chevron: .none)
                    SettingsDivider()
                    Link(destination: privacyURL) {
                        SettingsRow(icon: "hand.raised.fill", tint: Theme.good,
                                    title: "Privacy policy", chevron: .external)
                    }
                    SettingsDivider()
                    Link(destination: supportURL) {
                        SettingsRow(icon: "questionmark.circle.fill", tint: Color(hex: "C74B7A"),
                                    title: "Support", chevron: .external)
                    }
                    SettingsDivider()
                    Link(destination: sourceURL) {
                        SettingsRow(icon: "chevron.left.forwardslash.chevron.right", tint: Color(hex: "2F3A44"),
                                    title: "Source on GitHub", chevron: .external)
                    }
                }

                Text("Sightline · Made in Australia")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.faint)
                    .frame(maxWidth: .infinity).padding(.top, 6)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showAuth) { AuthView() }        }
    }

    // MARK: Account
    private var accountCard: some View {
        CardBox {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(auth.isAuthenticated ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surface3))
                    if auth.isAuthenticated {
                        Text(initial).font(Theme.display(18, .heavy)).foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.muted)
                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    if auth.isAuthenticated {
                        Text(auth.email ?? "").font(.system(size: 14.5, weight: .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                        Text("Signed in").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    } else {
                        Text("Not signed in").font(.system(size: 14.5, weight: .bold)).foregroundStyle(Theme.ink)
                        Text("Sign in to connect a real bank").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                }
                Spacer(minLength: 8)

                if auth.isAuthenticated {
                    Button {
                        Haptics.light()
                        auth.signOut()
                        Task { await store.setLiveData(false) }
                    } label: {
                        Text("Sign out").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.bad)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Theme.badSoft, in: Capsule())
                    }
                    .buttonStyle(.pressable)
                } else {
                    Button { Haptics.light(); showAuth = true } label: {
                        Text("Sign in").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Theme.accent, in: Capsule())
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }

    private var initial: String {
        String(auth.email?.first.map { String($0).uppercased() } ?? "S")
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// MARK: - Building blocks

/// A card holding a stack of settings rows.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        CardBox(padding: 0) { VStack(spacing: 0) { content } }
    }
}

struct SettingsDivider: View {
    var body: some View { Divider().overlay(Theme.line).padding(.leading, 58) }
}

struct SettingsRow: View {
    enum Chevron { case push, external, none }

    let icon: String
    let tint: Color
    let title: String
    var value: String? = nil
    var chevron: Chevron = .push

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            if let value {
                Text(value).font(.system(size: 12.5, weight: .medium)).foregroundStyle(Theme.muted).lineLimit(1)
            }
            switch chevron {
            case .push:
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.faint)
            case .external:
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.faint)
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
