import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var streak: StreakManager
    @State private var editing: BudgetCategory?
    @State private var showNewCategory = false
    @State private var showManage = false
    @State private var showAlerts = false
    @State private var showConnection = false
    @State private var showAppearance = false
    @State private var celebrate = false
    @State private var confettiID = UUID()
    @State private var hasCelebrated = false

    /// Confetti when you're comfortably under budget. Auto-fires once per session
    /// after data loads; `force` replays it on pull-to-refresh.
    private func celebrateIfUnder(force: Bool = false) {
        guard store.totalBudget > 0, store.overallStatus.kind == .good else { celebrate = false; return }
        guard force || !hasCelebrated else { return }
        hasCelebrated = true
        confettiID = UUID()
        celebrate = true
        Haptics.success()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 9) {
                        Text("S").font(Theme.display(16, .heavy)).foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        Text("Sightline").font(Theme.display(22, .heavy)).foregroundStyle(Theme.ink)
                    }
                    Spacer(minLength: 6)
                    Button { Haptics.light(); showConnection = true } label: { SourceBadge() }
                        .buttonStyle(.plain)
                    headerIcon("bell.fill", label: "Alerts") { showAlerts = true }
                    headerIcon("circle.lefthalf.filled", label: "Appearance") { showAppearance = true }
                }
                .padding(.top, 4)

                if let snap = store.snapshot {
                    heroCard(snap)
                    healthCard(snap)
                    StreakCard()

                    SectionHeader(title: "Where it's going")
                    CardBox { DonutBreakdown(categories: store.categories) }

                    SectionHeader(title: "Budgets", link: "Manage") { Haptics.light(); showManage = true }
                    CardBox(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(store.categories.enumerated()), id: \.element.id) { idx, cat in
                                if idx > 0 { Divider().overlay(Theme.line) }
                                CategoryRow(category: cat, glow: store.flashOverKey == cat.key)
                                    .onTapGesture { Haptics.light(); editing = cat }
                            }
                        }
                    }
                    Button {
                        Haptics.light()
                        showNewCategory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("New category")
                        }
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.accentInk)
                        .frame(maxWidth: .infinity).padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundStyle(Theme.lineStrong))
                    }
                    .buttonStyle(.pressable)
                    Text("Tap a category to adjust its budget, or add your own.")
                        .font(.system(size: 11)).foregroundStyle(Theme.faint).padding(.horizontal, 4)
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.bg)
        .refreshable {
            Haptics.select()
            await store.load()
            celebrateIfUnder(force: true)
        }
        .overlay(alignment: .top) {
            if celebrate {
                ConfettiView().id(confettiID).frame(height: 420).allowsHitTesting(false)
            }
        }
        .onChange(of: store.isLoading) { _, loading in if !loading { celebrateIfUnder() } }
        .onAppear { celebrateIfUnder() }
        // Streak badge earned → confetti + reward popup.
        .onChange(of: streak.newMilestone) { _, m in
            if m != nil { confettiID = UUID(); celebrate = true; Haptics.success() }
        }
        .overlay {
            if let m = streak.newMilestone {
                StreakRewardPopup(milestone: m, streakDays: streak.count) { streak.newMilestone = nil }
                    .transition(.opacity)
            }
        }
        .sheet(item: $editing) { cat in BudgetEditor(category: cat) }
        .sheet(isPresented: $showNewCategory) { CategoryCreatorSheet() }
        .sheet(isPresented: $showManage) { ManageCategoriesSheet() }
        .sheet(isPresented: $showAlerts) { AlertsSettingsSheet() }
        .sheet(isPresented: $showConnection) { BankConnectionSheet() }
        .sheet(isPresented: $showAppearance) { AppearanceSheet() }
    }

    private func headerIcon(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accentInk)
                .frame(width: 32, height: 32)
                .background(Theme.surface2, in: Circle())
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }

    // MARK: Hero
    private func heroCard(_ snap: FinanceSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Left to spend · \(snap.period)")
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
            AnimatedAUD(value: store.leftToSpend).font(Theme.mono(38)).foregroundStyle(.white)
                .padding(.top, 4)
            Text("of \(Money.aud(store.totalBudget)) budgeted · \(Money.aud(store.totalSpent)) spent so far")
                .font(.system(size: 12.5)).foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 10) {
                heroChip("Total budget", Money.aud(store.totalBudget))
                heroChip("Spent", Money.aud(store.totalSpent))
                heroChip("Saved", Money.aud(snap.savedThisMonth))
            }
            .padding(.top, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func heroChip(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(k).font(.system(size: 10.5)).foregroundStyle(.white.opacity(0.85))
            Text(v).font(Theme.mono(16)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func healthCard(_ snap: FinanceSnapshot) -> some View {
        let band = store.healthBand
        let s = store.overallStatus
        let underPct = store.totalBudget > 0 ? Int((1 - store.totalSpent / store.totalBudget) * 100 + 0.5) : 0
        let overPct = store.totalBudget > 0 ? Int((store.totalSpent / store.totalBudget - 1) * 100 + 0.5) : 0
        let message: String
        switch s.kind {
        case .good: message = "Spending \(underPct)% under budget this month — keep it up! 🎉"
        case .warn: message = "You've used most of your budget. Ease up where you can. 👀"
        case .bad:  message = "You're \(overPct)% over budget this month. 🚩"
        }
        return CardBox {
            HStack(spacing: 16) {
                HealthRing(score: store.healthScore, color: band.kind.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget health").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                    Text(band.label).font(Theme.display(19)).foregroundStyle(band.kind.color)
                    Text(message).font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Category row
struct CategoryRow: View {
    let category: BudgetCategory
    var glow: Bool = false
    @State private var flashOn = false
    var body: some View {
        let s = category.status
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 11) {
                Text(category.icon).font(.system(size: 18))
                    .frame(width: 38, height: 38)
                    .background(category.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name).font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.ink)
                    Text(s.message).font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                }
                Spacer()
                StatusPill(status: s)
            }
            ProgressBar(fraction: category.fractionUsed, color: s.kind.color)
            HStack {
                Text("\(Money.aud(category.spent)) spent").font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                Spacer()
                Text("of \(Money.aud(category.budget)) · \(Money.aud(category.remaining)) left")
                    .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
            }
        }
        .padding(14)
        .background(flashOn ? Theme.badSoft : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.bad.opacity(flashOn ? 0.9 : 0), lineWidth: 2.5)
                .padding(4)
        )
        .contentShape(Rectangle())
        .onAppear { if glow { pulse() } }
        .onChange(of: glow) { _, g in if g { pulse() } }
    }

    private func pulse() {
        withAnimation(.easeOut(duration: 0.2)) { flashOn = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeInOut(duration: 0.6)) { flashOn = false }
        }
    }
}

// MARK: - Budget editor sheet
struct BudgetEditor: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let category: BudgetCategory
    @State private var amount: Double = 0
    @State private var name = ""
    @State private var keywordsText = ""
    @State private var errorText: String?
    @FocusState private var focused: Bool
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Text(category.icon).font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(category.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading) {
                        Text(category.name).font(Theme.display(20)).foregroundStyle(Theme.ink)
                        Text("\(Money.aud(category.spent)) spent this month").font(.system(size: 13)).foregroundStyle(Theme.muted)
                    }
                }
                Text("Name").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                TextField("Category name", text: $name)
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
                    .padding(14)
                    .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))

                Text("Monthly budget").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                HStack {
                    Text("$").font(Theme.mono(30)).foregroundStyle(Theme.muted)
                    TextField("0", value: $amount, format: .number)
                        .font(Theme.mono(30)).foregroundStyle(Theme.ink)
                        .keyboardType(.numberPad)
                        .focused($focused)
                }
                .padding(16)
                .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))

                Text("Match keywords").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                TextField("e.g. gym, chemist, fitness", text: $keywordsText)
                    .font(.system(size: 14)).foregroundStyle(Theme.ink)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .padding(13)
                    .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))
                Text("Live transactions whose merchant contains a keyword land here.")
                    .font(.system(size: 11)).foregroundStyle(Theme.faint)

                let preview = BudgetStatus.evaluate(spent: category.spent, budget: amount)
                HStack {
                    Text("At this budget:").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    StatusPill(status: preview)
                }
                if let errorText {
                    Text(errorText).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.bad)
                }
                Spacer()
                Button { commit() } label: {
                    Text("Save changes").frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white).font(.system(size: 15, weight: .bold))
                }
                Button(role: .destructive) {
                    store.deleteCategory(for: category.id)
                    dismiss()
                } label: {
                    Text("Remove category").frame(maxWidth: .infinity).padding(.vertical, 12)
                        .foregroundStyle(Theme.bad).font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(20)
            .background(Theme.bg)
            .navigationTitle("Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { commit() }.bold() }
            }
            .onAppear {
                amount = category.budget
                name = category.name
                keywordsText = category.keywords.joined(separator: ", ")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true }
            }
        }
    }

    private func commit() {
        let newName = name.trimmingCharacters(in: .whitespaces)
        if newName != category.name, let err = store.renameCategory(for: category.id, to: newName) {
            errorText = err
            Haptics.warning()
            return
        }
        store.updateBudget(for: category.id, to: amount)
        store.updateKeywords(for: category.id, keywords: keywordsText.split(separator: ",").map(String.init))
        Haptics.success()
        dismiss()
    }
}
