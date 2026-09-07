import SwiftUI
import SwiftData

@MainActor
final class AppStore: ObservableObject {
    // Loaded data
    @Published var snapshot: FinanceSnapshot?
    @Published var categories: [BudgetCategory] = []   // budgets are persisted, spent is live
    @Published var goals: [Goal] = []

    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Use the live Basiq sandbox via the Sightline proxy (vs. sample data).
    /// Persisted, and toggled in-app from Home → the data-source badge.
    @Published var useLiveData = UserDefaults.standard.bool(forKey: "useLiveData") {
        didSet { UserDefaults.standard.set(useLiveData, forKey: "useLiveData") }
    }

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    private var service: BankService {
        useLiveData ? BasiqBankService() : MockBankService()
    }

    /// True only when a live snapshot actually loaded (not just intended).
    @Published private(set) var isShowingLive = false
    var isLive: Bool { isShowingLive }

    // Derived totals (reflect live budget edits)
    var totalBudget: Double { categories.reduce(0) { $0 + $1.budget } }
    var totalSpent: Double  { categories.reduce(0) { $0 + $1.spent } }
    var leftToSpend: Double { totalBudget - totalSpent }
    var overallStatus: BudgetStatus { BudgetStatus.evaluate(spent: totalSpent, budget: totalBudget) }

    // MARK: - Loading
    func load() async {
        isLoading = true
        errorMessage = nil
        // Ensure default categories/goals exist, then hand their rules to the
        // live feed so it can tag transactions onto them (custom ones included).
        seedBudgetsIfNeeded(from: SampleData.categories)
        seedGoalsIfNeeded(from: SampleData.goals)
        let rules = currentCategoryRules()

        var snap: FinanceSnapshot
        let source = service
        do {
            snap = try await source.loadSnapshot(categories: rules)
            isShowingLive = source.isLive         // live only if it actually succeeded
        } catch {
            errorMessage = error.localizedDescription
            snap = SampleData.snapshot            // never leave the app empty
            isShowingLive = false
        }
        snapshot = snap

        rebuildCategories(from: snap)
        rebuildGoals()
        reevaluateAlerts()

        isLoading = false
    }

    private func currentCategoryRules() -> [CategoryRule] {
        let items = (try? context.fetch(
            FetchDescriptor<BudgetItem>(sortBy: [SortDescriptor(\.order)])
        )) ?? []
        return items.map {
            CategoryRule(key: $0.key, name: $0.name, icon: $0.icon,
                         colorHex: $0.colorHex, budget: $0.budget, keywords: $0.keywords)
        }
    }

    /// Ask the proxy for the hosted Basiq Connect consent URL to open in-app.
    func fetchConsentURL() async -> (url: URL?, error: String?) {
        guard let base = BackendConfig.baseURL else { return (nil, "That doesn't look like a valid URL.") }
        guard let token = AuthManager.currentToken else { return (nil, "Sign in first to connect a bank.") }
        var request = URLRequest(url: base.appendingPathComponent("me/connect-token"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return (nil, "The proxy couldn't start a bank connection. Check that it's running with a valid Basiq key.")
            }
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let s = obj?["consentUrl"] as? String, let u = URL(string: s) { return (u, nil) }
            return (nil, "The proxy didn't return a consent URL.")
        } catch {
            return (nil, "Couldn't reach \(BackendConfig.baseURLString). Is the proxy running?")
        }
    }

    /// Switch data source and reload.
    func setLiveData(_ live: Bool) async {
        useLiveData = live
        await load()
    }

    /// Ping the proxy and report a human-readable result for the connection sheet.
    func testBackend() async -> String {
        guard let base = BackendConfig.baseURL else { return "That doesn't look like a valid URL." }
        guard let token = AuthManager.currentToken else { return "Sign in first, then test the connection." }
        var request = URLRequest(url: base.appendingPathComponent("me/snapshot"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["categories": []])
        do {
            let (data, resp) = try await URLSession.shared.data(for: request)
            guard let http = resp as? HTTPURLResponse else { return "No response from the proxy." }
            if (200...299).contains(http.statusCode) {
                let count = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?
                    .flatMap { ($0["accounts"] as? [Any])?.count } ?? 0
                return "Connected ✓ — \(count) account\(count == 1 ? "" : "s") from Basiq."
            }
            return "Proxy reachable but returned HTTP \(http.statusCode). Check your Basiq key and that `npm run seed` set BASIQ_USER_ID."
        } catch {
            return "Couldn't reach \(BackendConfig.baseURLString). Is the proxy running (npm start)?"
        }
    }

    /// Ask the notifier to fire alerts for any newly over-budget categories.
    func reevaluateAlerts() {
        NotificationManager.shared.evaluate(categories: categories, period: snapshot?.period ?? "")
    }

    // MARK: - Category mutations
    func updateBudget(for id: BudgetCategory.ID, to amount: Double) {
        guard let cat = categories.first(where: { $0.id == id }) else { return }
        let items = budgetItemsByKey()
        if let item = items[cat.key] {
            item.budget = max(0, amount)
        } else {
            context.insert(BudgetItem(key: cat.key, name: cat.name, icon: cat.icon,
                                      colorHex: cat.colorHex, budget: max(0, amount), order: categories.count))
        }
        save()
        if let snap = snapshot { rebuildCategories(from: snap) }
        reevaluateAlerts()   // a lowered budget may push a category over
    }

    /// Rename a category. Its identity (and spending link) is preserved.
    /// Returns nil on success, or a message explaining why it wasn't renamed.
    @discardableResult
    func renameCategory(for id: BudgetCategory.ID, to newName: String) -> String? {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Give the category a name." }
        guard let cat = categories.first(where: { $0.id == id }) else { return nil }
        let items = budgetItems()
        guard !items.contains(where: { $0.key != cat.key && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return "Another category is already called \u{201C}\(trimmed)\u{201D}."
        }
        items.first(where: { $0.key == cat.key })?.name = trimmed
        save()
        if let snap = snapshot { rebuildCategories(from: snap) }
        return nil
    }

    /// Returns nil on success, or a message explaining why the category wasn't added.
    @discardableResult
    func addCategory(name: String, icon: String, colorHex: String, budget: Double, keywords: [String] = []) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Give the category a name." }
        let items = budgetItems()
        guard !items.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return "A category called \u{201C}\(trimmed)\u{201D} already exists."
        }
        let maxOrder = items.map(\.order).max() ?? -1
        // Custom categories get a fresh unique key (they never match sample spend).
        context.insert(BudgetItem(key: "custom-" + UUID().uuidString, name: trimmed, icon: icon,
                                  colorHex: colorHex, budget: max(0, budget), order: maxOrder + 1,
                                  keywords: Self.cleanKeywords(keywords)))
        save()
        reloadForCategoryChange()
        return nil
    }

    /// Update a category's keywords (which merchants map to it).
    func updateKeywords(for id: BudgetCategory.ID, keywords: [String]) {
        guard let cat = categories.first(where: { $0.id == id }) else { return }
        budgetItemsByKey()[cat.key]?.keywords = Self.cleanKeywords(keywords)
        save()
        reloadForCategoryChange()
    }

    static func cleanKeywords(_ raw: [String]) -> [String] {
        var seen = Set<String>()
        return raw.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// Category rules changed → re-run the feed so live re-categorises.
    private func reloadForCategoryChange() {
        if let snap = snapshot { rebuildCategories(from: snap) }
        if useLiveData { Task { await load() } }
    }

    func deleteCategory(for id: BudgetCategory.ID) {
        guard let cat = categories.first(where: { $0.id == id }) else { return }
        if let item = budgetItemsByKey()[cat.key] {
            context.delete(item)
            save()
        }
        if let snap = snapshot { rebuildCategories(from: snap) }
    }

    /// Drag-to-reorder handler; persists the new order.
    func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        let byKey = budgetItemsByKey()
        for (idx, cat) in categories.enumerated() { byKey[cat.key]?.order = idx }
        save()
    }

    func addGoal(name: String, target: Double, dateLabel: String) {
        context.insert(GoalItem(name: name, target: target, saved: 0,
                                dateLabel: dateLabel, perWeek: 0, aheadOfPace: false))
        save()
        rebuildGoals()
    }

    func deleteGoal(_ goal: Goal) {
        let all = (try? context.fetch(FetchDescriptor<GoalItem>())) ?? []
        if let match = all.first(where: { $0.name == goal.name && $0.target == goal.target }) {
            context.delete(match)
            save()
            rebuildGoals()
        }
    }

    // MARK: - SwiftData helpers
    private func budgetItems() -> [BudgetItem] {
        (try? context.fetch(FetchDescriptor<BudgetItem>())) ?? []
    }
    private func budgetItemsByKey() -> [String: BudgetItem] {
        Dictionary(budgetItems().map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private func seedBudgetsIfNeeded(from snapshotCategories: [BudgetCategory]) {
        let existing = budgetItemsByKey()
        var didInsert = false
        for (idx, cat) in snapshotCategories.enumerated() where existing[cat.key] == nil {
            context.insert(BudgetItem(key: cat.key, name: cat.name, icon: cat.icon,
                                      colorHex: cat.colorHex, budget: cat.budget, order: idx,
                                      keywords: cat.keywords))
            didInsert = true
        }
        if didInsert { save() }
    }

    private func seedGoalsIfNeeded(from snapshotGoals: [Goal]) {
        let count = (try? context.fetchCount(FetchDescriptor<GoalItem>())) ?? 0
        guard count == 0 else { return }
        for (idx, g) in snapshotGoals.enumerated() {
            context.insert(GoalItem(name: g.name, target: g.target, saved: g.saved,
                                    dateLabel: g.dateLabel, perWeek: g.perWeek,
                                    aheadOfPace: g.aheadOfPace,
                                    createdAt: Date().addingTimeInterval(Double(idx))))
        }
        save()
    }

    /// Persisted budget items (incl. custom categories) are the source of truth for
    /// which categories exist; spend for each is looked up from the live snapshot.
    private func rebuildCategories(from snap: FinanceSnapshot) {
        let spentByKey = Dictionary(snap.categories.map { ($0.key, $0.spent) },
                                    uniquingKeysWith: { a, _ in a })
        let items = (try? context.fetch(
            FetchDescriptor<BudgetItem>(sortBy: [SortDescriptor(\.order)])
        )) ?? []
        var built = items.map { item in
            BudgetCategory(key: item.key, name: item.name, icon: item.icon, colorHex: item.colorHex,
                           budget: item.budget, spent: spentByKey[item.key] ?? 0, keywords: item.keywords)
        }
        // Surface snapshot-only categories with spend (e.g. live "Other").
        let persistedKeys = Set(items.map { $0.key })
        for cat in snap.categories where !persistedKeys.contains(cat.key) && cat.spent > 0 {
            built.append(cat)
        }
        categories = built
    }

    private func rebuildGoals() {
        let items = (try? context.fetch(
            FetchDescriptor<GoalItem>(sortBy: [SortDescriptor(\.createdAt)])
        )) ?? []
        goals = items.map { $0.asGoal }
    }

    private func save() {
        do { try context.save() }
        catch { errorMessage = "Couldn't save: \(error.localizedDescription)" }
    }
}
