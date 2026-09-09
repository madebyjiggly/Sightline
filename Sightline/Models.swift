import SwiftUI

// MARK: - Budget status logic
enum StatusKind {
    case good, warn, bad

    var color: Color {
        switch self {
        case .good: return Theme.good
        case .warn: return Theme.warn
        case .bad:  return Theme.bad
        }
    }
    var soft: Color {
        switch self {
        case .good: return Theme.goodSoft
        case .warn: return Theme.warnSoft
        case .bad:  return Theme.badSoft
        }
    }
}

struct BudgetStatus {
    let kind: StatusKind
    let pill: String     // short label e.g. "25% under"
    let message: String  // longer e.g. "25% under budget"

    /// Compares spending against a budget and returns a status.
    /// Under 85% used → good; 85–100% → getting close; over 100% → over budget.
    static func evaluate(spent: Double, budget: Double) -> BudgetStatus {
        guard budget > 0 else {
            return BudgetStatus(kind: .good, pill: "No budget", message: "No budget set")
        }
        let pct = spent / budget
        if pct > 1 {
            let diff = Int((pct - 1) * 100 + 0.5)
            return BudgetStatus(kind: .bad, pill: "\(diff)% over", message: "\(diff)% over budget")
        } else if pct >= 0.85 {
            return BudgetStatus(kind: .warn, pill: "\(Int(pct * 100 + 0.5))% used", message: "Getting close")
        } else {
            let diff = Int((1 - pct) * 100 + 0.5)
            return BudgetStatus(kind: .good, pill: "\(diff)% under", message: "\(diff)% under budget")
        }
    }
}

// MARK: - Domain models
struct BudgetCategory: Identifiable, Hashable {
    let id = UUID()
    var key: String       // stable identity (matches BudgetItem.key)
    var name: String
    var icon: String      // emoji
    var colorHex: String
    var budget: Double
    var spent: Double
    var keywords: [String] = []

    init(key: String? = nil, name: String, icon: String, colorHex: String, budget: Double, spent: Double, keywords: [String] = []) {
        self.key = key ?? name
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.budget = budget
        self.spent = spent
        self.keywords = keywords
    }

    var color: Color { Color(hex: colorHex) }
    var remaining: Double { budget - spent }
    var fractionUsed: Double { budget > 0 ? min(1, spent / budget) : 0 }
    var percentUsed: Int { budget > 0 ? Int((spent / budget) * 100 + 0.5) : 0 }
    var status: BudgetStatus { BudgetStatus.evaluate(spent: spent, budget: budget) }
}

enum AccountKind: String {
    case debit, savings, credit
}

struct Account: Identifiable, Hashable {
    let id = UUID()
    var nickname: String
    var kind: AccountKind
    var network: String       // "Visa Debit", "CommBank", ...
    var maskedNumber: String  // "•••• 4021"
    var balance: Double = 0   // for debit/savings
    var owing: Double = 0     // for credit
    var limit: Double = 0     // for credit

    var available: Double { limit - owing }
    var creditPercentUsed: Int { limit > 0 ? Int((owing / limit) * 100 + 0.5) : 0 }
}

struct Goal: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var target: Double
    var saved: Double
    var dateLabel: String
    var perWeek: Double
    var aheadOfPace: Bool

    var fraction: Double { target > 0 ? min(1, saved / target) : 0 }
    var percent: Int { target > 0 ? Int((saved / target) * 100 + 0.5) : 0 }
}

struct Txn: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var category: String
    var icon: String
    var amount: Double   // positive = spent
}

struct DaySpend: Identifiable, Hashable {
    let id = UUID()
    var weekdayShort: String   // "Mon"
    var dayLabel: String       // "Wed 3 Sep"
    var total: Double
    var txns: [Txn]
    var isToday: Bool = false
}

struct WeekBucket: Identifiable, Hashable {
    let id = UUID()
    var label: String   // "Week 1"
    var total: Double
}

/// The result of contributing toward a goal (drives milestone nudges + confetti).
enum GoalEvent: Equatable {
    case none
    case milestone(Int)   // crossed 25 / 50 / 75%
    case completed        // reached 100%
}

/// A category's definition sent to the proxy so it can tag live transactions.
struct CategoryRule: Codable {
    let key: String
    let name: String
    let icon: String
    let colorHex: String
    let budget: Double
    let keywords: [String]
}
