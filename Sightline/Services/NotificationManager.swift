import SwiftUI
import UserNotifications

/// Local (on-device) notifications for over-budget categories. No server or APNs
/// needed — the app schedules an alert the moment a category crosses its budget.
@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: Keys.enabled) } }
    @Published var authorized = false
    @Published var statusText = "unknown"

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let enabled = "notif.enabled"
        static let alertedKeys = "notif.alertedKeys"
        static let alertedPeriod = "notif.alertedPeriod"
    }

    private override init() {
        enabled = defaults.bool(forKey: Keys.enabled)
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshAuthStatus() }
    }

    // MARK: Authorization
    func refreshAuthStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        switch settings.authorizationStatus {
        case .notDetermined: statusText = "not asked yet"
        case .denied:        statusText = "denied"
        case .authorized:    statusText = "authorized"
        case .provisional:   statusText = "provisional"
        case .ephemeral:     statusText = "ephemeral"
        @unknown default:    statusText = "unknown"
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        authorized = granted
        await refreshAuthStatus()
        return granted
    }

    // MARK: Evaluation
    /// Fires a notification for any category that has newly crossed over budget
    /// this period. De-dupes so the user isn't alerted repeatedly for the same one.
    func evaluate(categories: [BudgetCategory], period: String) {
        guard enabled, authorized else { return }
        var alerted = alertedSet(for: period)
        for cat in categories {
            let isOver = cat.budget > 0 && cat.spent > cat.budget
            if isOver, !alerted.contains(cat.key) {
                send(title: "🚩 Over budget: \(cat.name)", body: overBody(cat))
                alerted.insert(cat.key)
            } else if !isOver {
                alerted.remove(cat.key)   // back under → allow a fresh alert later
            }
        }
        persist(alerted, period: period)
    }

    func sendTest() {
        send(title: "Sightline", body: "Test alert — this is how you'll hear when a category goes over budget.")
    }

    // MARK: Private
    private func overBody(_ cat: BudgetCategory) -> String {
        let overPct = Int((cat.spent / cat.budget - 1) * 100 + 0.5)
        return "You've spent \(Money.aud(cat.spent)) of your \(Money.aud(cat.budget)) \(cat.name) budget — \(overPct)% over."
    }

    private func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    private func alertedSet(for period: String) -> Set<String> {
        guard defaults.string(forKey: Keys.alertedPeriod) == period else { return [] }
        return Set(defaults.stringArray(forKey: Keys.alertedKeys) ?? [])
    }
    private func persist(_ set: Set<String>, period: String) {
        defaults.set(Array(set), forKey: Keys.alertedKeys)
        defaults.set(period, forKey: Keys.alertedPeriod)
    }

    // Show the banner even while the app is in the foreground.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
