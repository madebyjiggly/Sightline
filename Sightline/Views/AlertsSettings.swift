import SwiftUI

/// Alerts settings page. Pushed inside the Settings hub, or wrapped by
/// `AlertsSettingsSheet` when presented on its own.
struct AlertsSettingsContent: View {
    @EnvironmentObject var notifier: NotificationManager
    @EnvironmentObject var store: AppStore

    var body: some View {
        Screen(title: "Alerts") {
            CardBox {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $notifier.enabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Over-budget alerts").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                            Text("Get a notification when a category goes over budget.")
                                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.accent)
                    .onChange(of: notifier.enabled) { _, isOn in
                        guard isOn else { return }
                        Task {
                            let granted = await notifier.requestAuthorization()
                            if granted { store.reevaluateAlerts() }
                            else { notifier.enabled = false }   // permission denied
                        }
                    }

                    HStack(spacing: 6) {
                        Circle().fill(notifier.authorized ? Theme.good : Theme.warn).frame(width: 7, height: 7)
                        Text("Permission: \(notifier.statusText)")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                    }
                    if notifier.statusText == "denied" {
                        Text("Turn notifications on in iOS Settings › Sightline › Notifications.")
                            .font(.system(size: 12)).foregroundStyle(Theme.warn)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            CardBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text("How it works").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink)
                    bullet("You're alerted once per category each month, the moment its spending passes your budget.")
                    bullet("Change a budget lower than you've already spent and you'll hear about it straight away.")
                    bullet("Everything runs on-device — no data leaves your phone.")
                }
            }

            Button {
                Task {
                    if !notifier.authorized { await notifier.requestAuthorization() }
                    notifier.sendTest()
                }
            } label: {
                Text("Send a test alert").frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await notifier.refreshAuthStatus() }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 6)
            Text(text).font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AlertsSettingsSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            AlertsSettingsContent()
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
