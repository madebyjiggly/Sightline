import Foundation

// Realistic Australian sample data (AUD). Mirrors the approved prototype so the
// app opens in a believable working state before any bank is linked.
enum SampleData {

    static var categories: [BudgetCategory] = [
        BudgetCategory(name: "Groceries",        icon: "🛒", colorHex: "0E7C66", budget: 600,  spent: 445,
                       keywords: ["woolworths", "coles", "aldi", "iga", "grocery", "supermarket"]),
        BudgetCategory(name: "Food & Dining",    icon: "🍽️", colorHex: "C07B00", budget: 300,  spent: 412,
                       keywords: ["cafe", "coffee", "restaurant", "uber eats", "deliveroo", "mcdonald", "dining", "bar", "kfc"]),
        BudgetCategory(name: "House & Bills",    icon: "🏠", colorHex: "3E6BB0", budget: 1800, spent: 1650,
                       keywords: ["rent", "origin", "energy", "electricity", "telstra", "optus", "water", "internet", "insurance"]),
        BudgetCategory(name: "Cars & Transport", icon: "🚗", colorHex: "8A5BC7", budget: 400,  spent: 180,
                       keywords: ["bp", "shell", "caltex", "fuel", "petrol", "myki", "opal", "uber", "parking", "transport"]),
        BudgetCategory(name: "Entertainment",    icon: "🎬", colorHex: "C74B7A", budget: 200,  spent: 95,
                       keywords: ["spotify", "netflix", "cinema", "hoyts", "steam", "disney", "game"]),
    ]

    static var accounts: [Account] = [
        Account(nickname: "Everyday",     kind: .debit,   network: "Visa Debit", maskedNumber: "•••• 4021", balance: 2340),
        Account(nickname: "Savings",      kind: .savings, network: "CommBank",   maskedNumber: "•••• 7788", balance: 8750),
        Account(nickname: "Rewards Card", kind: .credit,  network: "Visa",       maskedNumber: "•••• 6610", owing: 1240, limit: 6000),
    ]

    static var goals: [Goal] = [
        Goal(name: "New car deposit", target: 5000, saved: 3200, dateLabel: "Dec 2025", perWeek: 120, aheadOfPace: true),
        Goal(name: "Emergency fund",  target: 3000, saved: 1150, dateLabel: "Mar 2026", perWeek: 80,  aheadOfPace: false),
    ]

    static let todayTxns: [Txn] = [
        Txn(name: "Woolworths",    category: "Groceries",        icon: "🛒", amount: 80),
        Txn(name: "Origin Energy", category: "House & Bills",    icon: "🏠", amount: 100),
        Txn(name: "BP Fuel",       category: "Cars & Transport", icon: "⛽", amount: 43),
    ]

    static var today = DaySpend(
        weekdayShort: "Thu", dayLabel: "Today · Thu 4 Sep", total: 223, txns: todayTxns, isToday: true
    )

    static var week: [DaySpend] = [
        DaySpend(weekdayShort: "Mon", dayLabel: "Mon 1 Sep", total: 64, txns: [
            Txn(name: "Coles", category: "Groceries", icon: "🛒", amount: 52),
            Txn(name: "Spotify", category: "Entertainment", icon: "🎬", amount: 12)]),
        DaySpend(weekdayShort: "Tue", dayLabel: "Tue 2 Sep", total: 38, txns: [
            Txn(name: "Cafe Lune", category: "Food & Dining", icon: "☕️", amount: 18),
            Txn(name: "Myki Top-up", category: "Cars & Transport", icon: "🚊", amount: 20)]),
        DaySpend(weekdayShort: "Wed", dayLabel: "Wed 3 Sep", total: 156, txns: [
            Txn(name: "Rent", category: "House & Bills", icon: "🏠", amount: 140),
            Txn(name: "Chemist Warehouse", category: "Groceries", icon: "🛒", amount: 16)]),
        DaySpend(weekdayShort: "Thu", dayLabel: "Today · Thu 4 Sep", total: 223, txns: todayTxns, isToday: true),
        DaySpend(weekdayShort: "Fri", dayLabel: "Fri 5 Sep", total: 0, txns: []),
        DaySpend(weekdayShort: "Sat", dayLabel: "Sat 6 Sep", total: 0, txns: []),
        DaySpend(weekdayShort: "Sun", dayLabel: "Sun 7 Sep", total: 0, txns: []),
    ]

    static var monthWeeks: [WeekBucket] = [
        WeekBucket(label: "Week 1", total: 612),
        WeekBucket(label: "Week 2", total: 889),
        WeekBucket(label: "Week 3", total: 757),
        WeekBucket(label: "Week 4 (so far)", total: 522),
    ]

    static let monthDailyHeat: [Int: Double] = [
        1: 41, 2: 0, 3: 156, 4: 223, 5: 64, 6: 22, 7: 0, 8: 88, 9: 130, 10: 47,
        11: 210, 12: 95, 13: 0, 14: 36, 15: 180, 16: 60, 17: 44, 18: 250, 19: 110, 20: 0,
        21: 0, 22: 75, 23: 140,
    ]

    static var snapshot: FinanceSnapshot {
        FinanceSnapshot(
            period: "September 2025",
            accounts: accounts,
            categories: categories,
            goals: goals,
            today: today,
            week: week,
            monthWeeks: monthWeeks,
            monthDailyHeat: monthDailyHeat,
            savedThisMonth: 640
        )
    }

    // Guided goal-planning questions shown on the Goals screen.
    static let goalQuestions: [(q: String, a: String)] = [
        ("How much can you set aside each week?", "$120 / week"),
        ("Which category could you cut back on to get there faster?", "Food & Dining — you're $112 over there"),
        ("By what date do you want to hit this goal?", "December 2025"),
        ("Where will the savings be kept?", "Savings •••• 7788"),
    ]
}
