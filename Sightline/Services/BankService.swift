import Foundation

// A complete snapshot of everything the UI needs for one period.
// The bank aggregator supplies accounts + transactions; budgets & goals are
// the user's own data. `MockBankService` returns a ready-made snapshot;
// `BasiqBankService` builds one from live Basiq data.
struct FinanceSnapshot {
    var period: String
    var accounts: [Account]
    var categories: [BudgetCategory]
    var goals: [Goal]
    var today: DaySpend
    var week: [DaySpend]
    var monthWeeks: [WeekBucket]
    var monthDailyHeat: [Int: Double]   // day-of-month → amount spent
    var savedThisMonth: Double

    var totalBudget: Double { categories.reduce(0) { $0 + $1.budget } }
    var totalSpent: Double  { categories.reduce(0) { $0 + $1.spent } }
    var leftToSpend: Double { totalBudget - totalSpent }
    var cash: Double  { accounts.filter { $0.kind != .credit }.reduce(0) { $0 + $1.balance } }
    var owing: Double { accounts.filter { $0.kind == .credit }.reduce(0) { $0 + $1.owing } }
    var peakWeek: WeekBucket { monthWeeks.max { $0.total < $1.total } ?? monthWeeks.first! }
}

// The one seam every data source implements. Swap the implementation to go
// from sample data to a live bank feed without touching any View.
protocol BankService {
    /// True when connected to a real bank aggregator (vs. sample data).
    var isLive: Bool { get }
    /// `categories` (with keywords) lets the live feed tag transactions onto the
    /// user's own categories, including custom ones.
    func loadSnapshot(categories: [CategoryRule]) async throws -> FinanceSnapshot
}

// MARK: - Sample-data implementation (default — no keys, runs offline)
struct MockBankService: BankService {
    var isLive: Bool { false }

    func loadSnapshot(categories: [CategoryRule]) async throws -> FinanceSnapshot {
        // Simulate a short network fetch so loading states are exercised.
        try? await Task.sleep(nanoseconds: 500_000_000)
        return SampleData.snapshot
    }
}

enum BankServiceError: LocalizedError {
    case notConfigured
    case notAuthed
    case http(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "No backend URL configured. Set the proxy URL in Bank connection."
        case .notAuthed:     return "Sign in to use live data."
        case .http(let code): return "Backend returned HTTP \(code)."
        case .decoding:       return "Could not read the response from the backend."
        }
    }
}
