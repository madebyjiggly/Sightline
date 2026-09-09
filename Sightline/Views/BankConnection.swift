import SwiftUI

/// Bank connection page. Pushed inside the Settings hub, or wrapped by
/// `BankConnectionSheet` when presented on its own.
struct BankConnectionContent: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var auth: AuthManager

    @State private var urlString = BackendConfig.baseURLString
    @State private var testing = false
    @State private var testResult: String?
    @State private var connecting = false
    @State private var consentSheet: IdentifiedURL?
    @State private var connectError: String?
    @State private var showAuth = false

    var body: some View {
        Screen(title: "Bank connection") {
            if !auth.isAuthenticated {
                CardBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sign in first").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                        Text("Create an account or sign in to connect a real bank and sync your budget.")
                            .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Button { showAuth = true } label: {
                            Text("Sign in / Create account").frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
                        }
                        .buttonStyle(.pressable)
                    }
                }
            }

            CardBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connect your bank").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                    Text("Securely link a real account through Basiq. You'll log in on your bank's own page — Sightline never sees your bank password.")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        guard auth.isAuthenticated else { showAuth = true; return }
                        connecting = true; connectError = nil
                        Task {
                            let result = await store.fetchConsentURL()
                            connecting = false
                            if let u = result.url { consentSheet = IdentifiedURL(url: u) }
                            else { connectError = result.error }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if connecting { ProgressView().tint(.white) }
                            Image(systemName: "building.columns.fill")
                            Text(connecting ? "Starting…" : "Connect a bank")
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
                    }
                    .buttonStyle(.pressable)
                    .disabled(connecting)
                    if let connectError {
                        Text(connectError).font(.system(size: 12)).foregroundStyle(Theme.bad)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            CardBox {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: Binding(
                        get: { store.isLive },
                        set: { newValue in
                            if newValue && !auth.isAuthenticated { showAuth = true; return }
                            BackendConfig.baseURLString = urlString
                            Task { await store.setLiveData(newValue) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use live data (Basiq)").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                            Text("Off = sample data. On = pull accounts & transactions from your Sightline proxy.")
                                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.accent)

                    HStack(spacing: 6) {
                        Circle().fill(store.isLive ? Theme.good : Theme.warn).frame(width: 7, height: 7)
                        Text(store.isLive ? "Live · Basiq" : "Sample data")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                    }
                    if let err = store.errorMessage, store.useLiveData {
                        Text(err).font(.system(size: 12)).foregroundStyle(Theme.bad)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            CardBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Proxy URL").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                    TextField(BackendConfig.defaultURLString, text: $urlString)
                        .font(Theme.mono(14)).foregroundStyle(Theme.ink)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(12)
                        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))
                        .onChange(of: urlString) { _, newValue in BackendConfig.baseURLString = newValue }

                    Button {
                        testing = true; testResult = nil
                        Task { testResult = await store.testBackend(); testing = false }
                    } label: {
                        HStack {
                            if testing { ProgressView().tint(.white) }
                            Text(testing ? "Testing…" : "Test connection")
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white).font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.pressable)
                    .disabled(testing)

                    if let testResult {
                        Text(testResult).font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(testResult.contains("✓") ? Theme.good : Theme.warn)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            CardBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Set up the proxy").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink)
                    step("1", "Get a free sandbox key at dashboard.basiq.io.")
                    step("2", "In server/: copy .env.example to .env and paste your key into BASIQ_API_KEY.")
                    step("3", "Run npm run seed, then put the printed BASIQ_USER_ID into .env.")
                    step("4", "Run npm start, then flip the switch above and tap Test connection.")
                    Text("Your key stays on the server — the app only talks to the proxy.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.faint)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 2)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $consentSheet, onDismiss: {
            // After the consent flow, switch to live and reload to pull the new connection.
            Task { await store.setLiveData(true) }
        }) { item in
            SafariView(url: item.url).ignoresSafeArea()
        }
        .sheet(isPresented: $showAuth) { AuthView() }
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n).font(.system(size: 12, weight: .heavy)).foregroundStyle(Theme.accentInk)
                .frame(width: 22, height: 22).background(Theme.accentSoft, in: Circle())
            Text(text).font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BankConnectionSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            BankConnectionContent()
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
