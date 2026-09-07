import Foundation
import SwiftData

// Persisted user data. Budgets and goals survive app launches; spending itself
// always comes fresh from the bank feed, so it is never stored here.

@Model
final class BudgetItem {
    // `key` is the stable identity (never changes) used to match spending from the
    // bank feed; `name` is the editable display label the user can rename.
    @Attribute(.unique) var key: String
    var name: String
    var icon: String
    var colorHex: String
    var budget: Double
    var order: Int
    /// Merchant/description keywords used to auto-assign live transactions.
    var keywords: [String] = []

    init(key: String, name: String, icon: String, colorHex: String, budget: Double, order: Int, keywords: [String] = []) {
        self.key = key
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.budget = budget
        self.order = order
        self.keywords = keywords
    }
}

@Model
final class GoalItem {
    var name: String
    var target: Double
    var saved: Double
    var dateLabel: String
    var perWeek: Double
    var aheadOfPace: Bool
    var createdAt: Date

    init(name: String, target: Double, saved: Double,
         dateLabel: String, perWeek: Double, aheadOfPace: Bool, createdAt: Date = .now) {
        self.name = name
        self.target = target
        self.saved = saved
        self.dateLabel = dateLabel
        self.perWeek = perWeek
        self.aheadOfPace = aheadOfPace
        self.createdAt = createdAt
    }

    // Bridge to the view-layer struct.
    var asGoal: Goal {
        Goal(name: name, target: target, saved: saved,
             dateLabel: dateLabel, perWeek: perWeek, aheadOfPace: aheadOfPace)
    }
}
