import Foundation

// Where the Sightline backend proxy lives. The Basiq SECRET KEY stays on that
// server and is never shipped in the app. Point this at your running proxy.
enum BackendConfig {
    private static let urlKey = "backend.url"
    static let defaultURLString = "http://localhost:4000"

    /// The proxy URL, editable in-app (Home → tap the data-source badge) and persisted.
    static var baseURLString: String {
        get { UserDefaults.standard.string(forKey: urlKey) ?? defaultURLString }
        set { UserDefaults.standard.set(newValue, forKey: urlKey) }
    }
    static var baseURL: URL? { URL(string: baseURLString.trimmingCharacters(in: .whitespaces)) }

    // A demo user id the backend maps to a Basiq user. In a real app this comes
    // from your own auth system after the user signs in.
    static var demoUserId = "demo-user"
}

// MARK: - Backend DTOs (normalized by the proxy so the app stays simple)
private struct AccountDTO: Decodable {
    let nickname: String
    let kind: String        // "debit" | "savings" | "credit"
    let network: String
    let maskedNumber: String
    let balance: Double?
    let owing: Double?
    let limit: Double?
}

private struct TxnDTO: Decodable {
    let name: String        // merchant / description
    let key: String         // category key assigned by the proxy (or "other")
    let amount: Double      // positive = money spent
    let date: String        // ISO-8601 (yyyy-MM-dd)
}

private struct SnapshotDTO: Decodable {
    let accounts: [AccountDTO]
    let transactions: [TxnDTO]
}

/// A dated, categorised transaction from the live feed.
struct DatedTxn {
    let key: String
    let name: String
    let amount: Double
    let date: Date
}

// MARK: - Live Basiq implementation (Australia / CDR, sandbox or production)
struct BasiqBankService: BankService {
    var isLive: Bool { true }

    func loadSnapshot(categories rules: [CategoryRule]) async throws -> FinanceSnapshot {
        guard let base = BackendConfig.baseURL else { throw BankServiceError.notConfigured }
        guard let token = AuthManager.currentToken else { throw BankServiceError.notAuthed }
        var req = URLRequest(url: base.appendingPathComponent("me/snapshot"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Send only what the proxy needs to categorise: key + keywords.
        let rulePayload = rules.map { ["key": $0.key, "keywords": $0.keywords] as [String: Any] }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["categories": rulePayload])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw BankServiceError.decoding }
        if http.statusCode == 401 { throw BankServiceError.notAuthed }
        guard (200...299).contains(http.statusCode) else { throw BankServiceError.http(http.statusCode) }

        let dto: SnapshotDTO
        do { dto = try JSONDecoder().decode(SnapshotDTO.self, from: data) }
        catch { throw BankServiceError.decoding }

        let accounts = dto.accounts.map { a in
            Account(nickname: a.nickname,
                    kind: AccountKind(rawValue: a.kind) ?? .debit,
                    network: a.network,
                    maskedNumber: a.maskedNumber,
                    balance: a.balance ?? 0,
                    owing: a.owing ?? 0,
                    limit: a.limit ?? 0)
        }

        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        iso.locale = Locale(identifier: "en_AU")
        let txns: [DatedTxn] = dto.transactions.compactMap { t in
            guard let d = iso.date(from: t.date) else { return nil }
            return DatedTxn(key: t.key, name: t.name, amount: t.amount, date: d)
        }

        return SnapshotBuilder.build(accounts: accounts, dated: txns, rules: rules)
    }
}

// MARK: - Turns live accounts + categorised transactions into a FinanceSnapshot.
enum SnapshotBuilder {
    static func build(accounts: [Account], dated: [DatedTxn], rules: [CategoryRule], now: Date = Date()) -> FinanceSnapshot {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.year, .month], from: now)
        let monthTxns = dated.filter {
            let c = cal.dateComponents([.year, .month], from: $0.date)
            return c.year == comps.year && c.month == comps.month
        }

        // Display metadata per key, so calendar rows show the right name + icon.
        var meta: [String: (name: String, icon: String, color: String)] = [:]
        for r in rules { meta[r.key] = (r.name, r.icon, r.colorHex) }
        func display(_ key: String) -> (name: String, icon: String, color: String) {
            meta[key] ?? ("Other", "🗂", "8A988F")
        }
        func toTxn(_ t: DatedTxn) -> Txn {
            let d = display(t.key)
            return Txn(name: t.name, category: d.name, icon: d.icon, amount: t.amount)
        }

        // Category spend this month, keyed by the user's own categories.
        var categories = rules.map { r -> BudgetCategory in
            BudgetCategory(key: r.key, name: r.name, icon: r.icon, colorHex: r.colorHex,
                           budget: r.budget,
                           spent: monthTxns.filter { $0.key == r.key }.reduce(0) { $0 + $1.amount },
                           keywords: r.keywords)
        }
        // Surface any uncategorised spend as an "Other" row (budget 0).
        let otherSpent = monthTxns.filter { meta[$0.key] == nil }.reduce(0) { $0 + $1.amount }
        if otherSpent > 0 {
            categories.append(BudgetCategory(key: "other", name: "Other", icon: "🗂",
                                             colorHex: "8A988F", budget: 0, spent: otherSpent))
        }

        // Today
        let todayTxns = dated.filter { cal.isDate($0.date, inSameDayAs: now) }.map(toTxn)
        let today = DaySpend(weekdayShort: shortDay(now, cal),
                             dayLabel: "Today · " + longDay(now),
                             total: todayTxns.reduce(0) { $0 + $1.amount },
                             txns: todayTxns, isToday: true)

        // Current week (Mon–Sun)
        let weekInterval = cal.dateInterval(of: .weekOfYear, for: now)
        var week: [DaySpend] = []
        if let start = weekInterval?.start {
            for offset in 0..<7 {
                if let day = cal.date(byAdding: .day, value: offset, to: start) {
                    let dayTxns = dated.filter { cal.isDate($0.date, inSameDayAs: day) }.map(toTxn)
                    week.append(DaySpend(weekdayShort: shortDay(day, cal),
                                         dayLabel: longDay(day),
                                         total: dayTxns.reduce(0) { $0 + $1.amount },
                                         txns: dayTxns,
                                         isToday: cal.isDate(day, inSameDayAs: now)))
                }
            }
        }

        // Weeks of the month + daily heatmap
        var weekTotals: [Int: Double] = [:]
        var heat: [Int: Double] = [:]
        for item in monthTxns {
            let woy = cal.component(.weekOfMonth, from: item.date)
            weekTotals[woy, default: 0] += item.amount
            let dom = cal.component(.day, from: item.date)
            heat[dom, default: 0] += item.amount
        }
        let monthWeeks = weekTotals.keys.sorted().map {
            WeekBucket(label: "Week \($0)", total: weekTotals[$0] ?? 0)
        }

        let periodFmt = DateFormatter()
        periodFmt.dateFormat = "MMMM yyyy"
        periodFmt.locale = Locale(identifier: "en_AU")

        return FinanceSnapshot(
            period: periodFmt.string(from: now),
            accounts: accounts,
            categories: categories,
            goals: SampleData.goals,          // goals are local user data
            today: today,
            week: week.isEmpty ? SampleData.week : week,
            monthWeeks: monthWeeks.isEmpty ? SampleData.monthWeeks : monthWeeks,
            monthDailyHeat: heat,
            savedThisMonth: 0
        )
    }

    private static func shortDay(_ d: Date, _ cal: Calendar) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_AU"); f.dateFormat = "EEE"
        return f.string(from: d)
    }
    private static func longDay(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_AU"); f.dateFormat = "EEE d MMM"
        return f.string(from: d)
    }
}
