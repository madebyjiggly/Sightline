import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing: BudgetCategory?
    @State private var showNewCategory = false
    @State private var showManage = false
    @State private var showAlerts = false
    @State private var showConnection = false
    @State private var showAppearance = false

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
                    Button { showConnection = true } label: { SourceBadge() }
                        .buttonStyle(.plain)
                    headerIcon("bell.fill", label: "Alerts") { showAlerts = true }
                    headerIcon("circle.lefthalf.filled", label: "Appearance") { showAppearance = true }
                }
                .padding(.top, 4)

                if let snap = store.snapshot {
                    heroCard(snap)
                    overallBanner(snap)

                    SectionHeader(title: "Where it's going")
                    CardBox { DonutBreakdown(categories: store.categories) }

                    SectionHeader(title: "Budgets", link: "Manage") { showManage = true }
                    CardBox(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(store.categories.enumerated()), id: \.element.id) { idx, cat in
                                if idx > 0 { Divider().overlay(Theme.line) }
                                CategoryRow(category: cat).onTapGesture { editing = cat }
                            }
                        }
                    }
                    Button {
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
        .sheet(item: $editing) { cat in BudgetEditor(category: cat) }
        .sheet(isPresented: $showNewCategory) { CategoryCreatorSheet() }
        .sheet(isPresented: $showManage) { ManageCategoriesSheet() }
        .sheet(isPresented: $showAlerts) { AlertsSettingsSheet() }
        .sheet(isPresented: $showConnection) { BankConnectionSheet() }
        .sheet(isPresented: $showAppearance) { AppearanceSheet() }
    }

    private func headerIcon(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            Text(Money.aud(store.leftToSpend)).font(Theme.mono(38)).foregroundStyle(.white)
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

    private func overallBanner(_ snap: FinanceSnapshot) -> some View {
        let s = store.overallStatus
        let underPct = store.totalBudget > 0 ? Int((1 - store.totalSpent / store.totalBudget) * 100 + 0.5) : 0
        let overPct = store.totalBudget > 0 ? Int((store.totalSpent / store.totalBudget - 1) * 100 + 0.5) : 0
        let content: (String, String, String)
        switch s.kind {
        case .good: content = ("🎉", "You're under budget", "Spending \(underPct)% less than your total budget this month — great work.")
        case .warn: content = ("👀", "Getting close to budget", "You've used most of your budget for the month. Ease up where you can.")
        case .bad:  content = ("🚩", "You're over budget", "You're \(overPct)% over your total budget this month.")
        }
        return StatusBanner(emoji: content.0, title: content.1, detail: content.2, kind: s.kind)
    }
}

// MARK: - Category row
struct CategoryRow: View {
    let category: BudgetCategory
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
        .contentShape(Rectangle())
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
            return
        }
        store.updateBudget(for: category.id, to: amount)
        store.updateKeywords(for: category.id, keywords: keywordsText.split(separator: ",").map(String.init))
        dismiss()
    }
}
