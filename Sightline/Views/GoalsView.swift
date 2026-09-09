import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var newGoalText = ""
    @State private var celebrate = false
    @State private var confettiID = UUID()

    var body: some View {
        Screen(title: "Goals") {
            SectionHeader(title: "Your goals")
            ForEach(store.goals) { goal in
                GoalCard(goal: goal, onComplete: celebrateGoal)
                    .contextMenu {
                        Button(role: .destructive) { store.deleteGoal(goal) } label: {
                            Label("Delete goal", systemImage: "trash")
                        }
                    }
            }

            SectionHeader(title: "Add a goal")
            CardBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Describe a financial goal in your own words.")
                        .font(.system(size: 13)).foregroundStyle(Theme.muted)
                    HStack(spacing: 8) {
                        TextField("e.g. Save $5,000 for a car by December", text: $newGoalText)
                            .font(.system(size: 13))
                            .padding(11)
                            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.lineStrong, lineWidth: 1))
                        Button {
                            addGoal()
                        } label: {
                            Text("Add").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.pressable)
                    }
                }
            }

            SectionHeader(title: "Let's make a plan")
            CardBox {
                VStack(alignment: .leading, spacing: 0) {
                    Text("A few questions to help you reach it:")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                        .padding(.bottom, 4)
                    ForEach(Array(SampleData.goalQuestions.enumerated()), id: \.offset) { idx, item in
                        if idx > 0 { Divider().overlay(Theme.line) }
                        HStack(alignment: .top, spacing: 11) {
                            Text("\(idx + 1)").font(.system(size: 12, weight: .heavy)).foregroundStyle(Theme.accentInk)
                                .frame(width: 24, height: 24)
                                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.q).font(.system(size: 13)).foregroundStyle(Theme.ink)
                                Text("↳ \(item.a)").font(.system(size: 12.5, weight: .bold)).foregroundStyle(Theme.accentInk)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if celebrate {
                ConfettiView().id(confettiID).frame(height: 460).allowsHitTesting(false)
            }
        }
    }

    private func celebrateGoal() {
        confettiID = UUID()
        celebrate = true
        Haptics.success()
    }

    private func addGoal() {
        let text = newGoalText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        // Naive parse of a "$5000" amount from the free text.
        let digits = text.filter { $0.isNumber }
        let target = Double(digits) ?? 1000
        store.addGoal(name: text, target: target, dateLabel: "Set a date")
        newGoalText = ""
        Haptics.success()
    }
}

struct GoalCard: View {
    @EnvironmentObject var store: AppStore
    let goal: Goal
    var onComplete: () -> Void = {}

    private var complete: Bool { goal.percent >= 100 }
    private let quickAmounts: [Double] = [50, 100, 250]

    var body: some View {
        CardBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name).font(Theme.display(16)).foregroundStyle(Theme.ink).lineLimit(2)
                        Text("Target \(Money.aud(goal.target)) by \(goal.dateLabel)" +
                             (goal.perWeek > 0 ? " · \(Money.aud(goal.perWeek))/week" : ""))
                            .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text(complete ? "Reached 🎉" : "\(goal.percent)%")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Theme.goodSoft, in: Capsule()).foregroundStyle(Theme.good)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    AnimatedAUD(value: goal.saved).font(Theme.mono(24)).foregroundStyle(Theme.ink)
                    Text("/ \(Money.aud(goal.target))").font(Theme.mono(13)).foregroundStyle(Theme.muted)
                }
                .padding(.top, 4)

                ProgressBar(fraction: goal.fraction, color: Theme.good)

                if complete {
                    Label("Goal reached — nice work!", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.good)
                        .padding(.top, 2)
                } else {
                    HStack(spacing: 8) {
                        Text("Add:").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        ForEach(quickAmounts, id: \.self) { amt in
                            Button {
                                Haptics.light()
                                if store.contributeToGoal(goal, amount: amt) { onComplete() }
                            } label: {
                                Text("+\(Money.aud(amt))")
                                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accentInk)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Theme.accentSoft, in: Capsule())
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
