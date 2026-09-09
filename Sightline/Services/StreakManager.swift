import SwiftUI

/// A badge awarded when the daily streak reaches a milestone.
struct StreakMilestone: Equatable, Identifiable {
    let days: Int
    let emoji: String
    let title: String
    var id: Int { days }
}

/// A daily check-in streak (🔥) — increments when the app is opened on
/// consecutive days, resets after a missed day. Persisted, entirely on-device.
/// Reaching a milestone earns a badge (kept even if the streak later resets).
@MainActor
final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    static let milestones: [StreakMilestone] = [
        StreakMilestone(days: 3,   emoji: "🥉", title: "Getting going"),
        StreakMilestone(days: 7,   emoji: "🥈", title: "Week Warrior"),
        StreakMilestone(days: 14,  emoji: "🏅", title: "Two weeks strong"),
        StreakMilestone(days: 30,  emoji: "🥇", title: "Monthly Master"),
        StreakMilestone(days: 100, emoji: "💎", title: "Century Club"),
    ]

    @Published private(set) var count: Int
    @Published private(set) var earned: [Int]          // milestone days already awarded
    @Published var newMilestone: StreakMilestone?      // set when a badge is just earned

    private let defaults = UserDefaults.standard
    private let fmt: DateFormatter
    private enum Keys {
        static let count = "streak.count"; static let last = "streak.last"; static let earned = "streak.earned"
    }

    private init() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_AU")
        fmt = f
        count = defaults.integer(forKey: Keys.count)
        earned = defaults.array(forKey: Keys.earned) as? [Int] ?? []
    }

    var nextMilestone: StreakMilestone? { Self.milestones.first { $0.days > count } }
    var earnedMilestones: [StreakMilestone] { Self.milestones.filter { earned.contains($0.days) } }

    /// Call when the app becomes active. Grows the streak once per day and
    /// awards a badge if a milestone is reached.
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

        if let m = Self.milestones.first(where: { $0.days == c }), !earned.contains(c) {
            earned.append(c)
            defaults.set(earned, forKey: Keys.earned)
            newMilestone = m
        }
    }
}
