import SwiftUI

/// A daily check-in streak (🔥) — increments when the app is opened on
/// consecutive days, resets after a missed day. Persisted, entirely on-device.
@MainActor
final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published private(set) var count: Int

    private let defaults = UserDefaults.standard
    private let fmt: DateFormatter
    private enum Keys { static let count = "streak.count"; static let last = "streak.last" }

    private init() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_AU")
        fmt = f
        count = defaults.integer(forKey: Keys.count)
    }

    /// Call when the app becomes active. Grows the streak once per day.
    func recordVisit() {
        let today = fmt.string(from: Date())
        let last = defaults.string(forKey: Keys.last)
        guard last != today else { return }   // already counted today

        let yesterday = fmt.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        var c = defaults.integer(forKey: Keys.count)
        c = (last == yesterday) ? c + 1 : 1

        defaults.set(c, forKey: Keys.count)
        defaults.set(today, forKey: Keys.last)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { count = c }
    }
}
