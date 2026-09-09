import SwiftUI

enum CalMode: String, CaseIterable, Identifiable { case day = "Day", week = "Week", month = "Month"; var id: String { rawValue } }

struct CalendarView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode: CalMode = .day
    @State private var selectedDay: DaySpend?

    var body: some View {
        Screen(title: "Calendar") {
            Picker("View", selection: $mode) {
                ForEach(CalMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in Haptics.select() }

            if let snap = store.snapshot {
                switch mode {
                case .day:   dayView(snap)
                case .week:  weekView(snap)
                case .month: monthView(snap)
                }
            }
        }
        .sheet(item: $selectedDay) { day in DayDetailSheet(day: day) }
    }

    // MARK: Day
    private func dayView(_ snap: FinanceSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            heroTotal(label: snap.today.dayLabel, value: snap.today.total,
                      sub: "total spent today across \(snap.today.txns.count) categories")
            SectionHeader(title: "Transactions")
            CardBox { TxnList(txns: snap.today.txns) }
        }
    }

    // MARK: Week
    private func weekView(_ snap: FinanceSnapshot) -> some View {
        let wkTotal = snap.week.reduce(0) { $0 + $1.total }
        let detail = snap.week.first(where: { !$0.txns.isEmpty && !$0.isToday }) ?? snap.week[0]
        return VStack(alignment: .leading, spacing: 14) {
            CardBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("This week").font(Theme.display(16)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text(Money.aud(wkTotal)).font(Theme.mono(15)).foregroundStyle(Theme.accentInk)
                    }
                    WeeklyBars(week: snap.week) { day in
                        if !day.txns.isEmpty { selectedDay = day }
                    }
                }
            }
            SectionHeader(title: "\(detail.dayLabel) · \(Money.aud(detail.total))")
            CardBox { TxnList(txns: detail.txns) }
            Text("Tap any bar to see that day's transactions.")
                .font(.system(size: 11)).foregroundStyle(Theme.faint).padding(.horizontal, 4)
        }
    }

    // MARK: Month
    private func monthView(_ snap: FinanceSnapshot) -> some View {
        let monthTotal = snap.monthWeeks.reduce(0) { $0 + $1.total }
        let peak = snap.peakWeek
        let (days, offset) = monthGeometry()
        return VStack(alignment: .leading, spacing: 14) {
            heroTotal(label: snap.period, value: monthTotal, sub: "total spent this month")
            HStack(spacing: 10) {
                StatTile(label: "Peak week", value: Money.aud(peak.total))
                StatTile(label: "Avg / week", value: Money.aud(monthTotal / 4))
                StatTile(label: "Avg / day", value: Money.aud(monthTotal / 30))
            }
            StatusBanner(emoji: "📈",
                         title: "Highest spend was \(peak.label)",
                         detail: "You spent \(Money.aud(peak.total)) that week — mostly on House & Bills and Groceries.",
                         kind: .warn)
            SectionHeader(title: "Daily heatmap")
            CardBox { MonthHeatmap(heat: snap.monthDailyHeat, daysInMonth: days, firstWeekdayOffset: offset) }
        }
    }

    // MARK: helpers
    private func heroTotal(label: String, value: Double, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
            AnimatedAUD(value: value).font(Theme.mono(38)).foregroundStyle(.white).padding(.top, 4)
            Text(sub).font(.system(size: 12.5)).foregroundStyle(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient)
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.07)).frame(width: 170, height: 170).offset(x: 55, y: -75)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Theme.heroTop.opacity(0.32), radius: 22, x: 0, y: 12)
    }

    /// Days-in-month and the Monday-based offset of the 1st.
    private func monthGeometry() -> (days: Int, offset: Int) {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2
        let ref: Date
        if store.isLive {
            ref = Date()
        } else {
            ref = cal.date(from: DateComponents(year: 2025, month: 9, day: 1)) ?? Date()
        }
        let range = cal.range(of: .day, in: .month, for: ref) ?? (1..<31)
        let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: ref)) ?? ref
        let weekday = cal.component(.weekday, from: firstOfMonth) // 1=Sun..7=Sat
        // Convert to Monday-based offset (Mon=0)
        let offset = (weekday + 5) % 7
        return (range.count, offset)
    }
}

// MARK: - Transaction list + day detail
struct TxnList: View {
    let txns: [Txn]
    var body: some View {
        if txns.isEmpty {
            Text("No spending recorded.").font(.system(size: 13)).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(txns.enumerated()), id: \.element.id) { idx, t in
                    if idx > 0 { Divider().overlay(Theme.line) }
                    HStack(spacing: 11) {
                        Text(t.icon).font(.system(size: 15))
                            .frame(width: 34, height: 34)
                            .background(Theme.surface3, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(t.name).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(Theme.ink)
                            Text(t.category).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Text("-\(Money.aud(t.amount))").font(Theme.mono(14)).foregroundStyle(Theme.ink)
                    }
                    .padding(.vertical, 11)
                }
            }
        }
    }
}

struct DayDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let day: DaySpend
    var body: some View {
        NavigationStack {
            Screen(title: day.dayLabel) {
                Text("\(Money.aud(day.total)) spent").font(Theme.mono(24)).foregroundStyle(Theme.ink)
                CardBox { TxnList(txns: day.txns) }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
