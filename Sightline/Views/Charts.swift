import SwiftUI

// MARK: - Budget health ring (gamified 0–100 score)
struct HealthRing: View {
    let score: Int
    let color: Color
    var size: CGFloat = 90
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surface3, lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: -1) {
                AnimatedInt(value: score).font(Theme.mono(24)).foregroundStyle(Theme.ink)
                Text("/ 100").font(.system(size: 9, weight: .semibold)).foregroundStyle(Theme.muted)
            }
        }
        .frame(width: size, height: size)
        .onAppear { animate() }
        .onChange(of: score) { _, _ in animate() }
    }

    private func animate() {
        progress = 0
        withAnimation(.easeOut(duration: 1.0)) { progress = CGFloat(score) / 100 }
    }
}

// MARK: - Donut + legend (category spend breakdown)
struct DonutBreakdown: View {
    let categories: [BudgetCategory]
    @State private var progress: CGFloat = 0

    private var total: Double { max(1, categories.reduce(0) { $0 + $1.spent }) }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                // Segmented look: a hairline gap between slices (flat caps so small
                // slices stay crisp instead of bulging into their neighbours).
                ForEach(segments()) { seg in
                    let gap: CGFloat = 0.006
                    let end = seg.start + (seg.end - seg.start) * progress
                    Circle()
                        .trim(from: min(seg.start + gap, end), to: max(end - gap, seg.start + gap))
                        .stroke(seg.color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 0) {
                    Text(Money.aud(categories.reduce(0) { $0 + $1.spent }))
                        .font(Theme.mono(18)).foregroundStyle(Theme.ink)
                    Text("spent").font(.system(size: 10)).foregroundStyle(Theme.muted)
                }
                .opacity(Double(progress))
            }
            .frame(width: 132, height: 132)
            .onAppear { withAnimation(.easeOut(duration: 1.0)) { progress = 1 } }
            .onChange(of: categories) { _, _ in
                progress = 0
                withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(categories) { c in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3).fill(c.color).frame(width: 10, height: 10)
                        Text(c.name).font(.system(size: 12)).foregroundStyle(Theme.muted).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(Money.aud(c.spent)).font(Theme.mono(12)).foregroundStyle(Theme.ink)
                    }
                }
            }
        }
    }

    private struct Seg: Identifiable { let id = UUID(); let start: CGFloat; let end: CGFloat; let color: Color }
    private func segments() -> [Seg] {
        var out: [Seg] = []; var acc: CGFloat = 0
        for c in categories {
            let frac = CGFloat(c.spent) / CGFloat(total)
            out.append(Seg(start: acc, end: acc + frac, color: c.color))
            acc += frac
        }
        return out
    }
}

// MARK: - Weekly bar chart
struct WeeklyBars: View {
    let week: [DaySpend]
    var onSelect: (DaySpend) -> Void = { _ in }
    @State private var grow: CGFloat = 0

    private var maxVal: Double { max(1, week.map { $0.total }.max() ?? 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(week) { day in
                VStack(spacing: 6) {
                    Text(day.total > 0 ? Money.aud(day.total) : " ")
                        .font(Theme.mono(9)).foregroundStyle(Theme.faint)
                    GeometryReader { geo in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Theme.accent)
                                .frame(height: max(4, geo.size.height * CGFloat(day.total / maxVal) * grow))
                                .overlay(
                                    day.isToday ?
                                    RoundedRectangle(cornerRadius: 6).stroke(Theme.accentSoft, lineWidth: 3) : nil
                                )
                        }
                    }
                    .frame(maxWidth: 26)
                    Text(day.weekdayShort).font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(day.isToday ? Theme.accentInk : Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { Haptics.light(); onSelect(day) }
            }
        }
        .frame(height: 130)
        .onAppear { grow = 0; withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) { grow = 1 } }
    }
}

// MARK: - Month heatmap
struct MonthHeatmap: View {
    let heat: [Int: Double]        // day-of-month → spend
    let daysInMonth: Int
    let firstWeekdayOffset: Int    // 0 = month starts Monday

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    var body: some View {
        LazyVGrid(columns: cols, spacing: 5) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { d in
                Text(d).font(.system(size: 9.5, weight: .bold)).foregroundStyle(Theme.faint)
            }
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in Color.clear.frame(height: 40) }
            ForEach(1...max(1, daysInMonth), id: \.self) { day in
                cell(day)
            }
        }
    }

    private func cell(_ day: Int) -> some View {
        let v = heat[day] ?? 0
        let bg: Color
        let fg: Color
        switch v {
        case 0:          bg = Theme.surface2;  fg = Theme.ink
        case ..<80:      bg = Theme.accentSoft; fg = Theme.ink
        case 80..<160:   bg = Theme.accent.opacity(0.35); fg = Theme.ink
        default:         bg = Theme.accent; fg = .white
        }
        return VStack(spacing: 1) {
            Text("\(day)").font(.system(size: 10, weight: .bold)).foregroundStyle(fg)
            if v > 0 {
                Text(Money.aud(v)).font(Theme.mono(8)).foregroundStyle(fg.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(bg, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
