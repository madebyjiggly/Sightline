import SwiftUI

struct CardsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showLinkInfo = false

    var body: some View {
        Screen(title: "Accounts & cards") {
            if let snap = store.snapshot {
                HStack(spacing: 10) {
                    StatTile(label: "Total cash", value: Money.aud(snap.cash), valueColor: Theme.good)
                    StatTile(label: "Credit owing", value: Money.aud(snap.owing), valueColor: Theme.bad)
                }
                VStack(spacing: 12) {
                    ForEach(snap.accounts) { BankCardView(account: $0) }
                }
                Button {
                    showLinkInfo = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Link another account or card")
                    }
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundStyle(Theme.lineStrong))
                }
                Text("Linking uses the aggregator's secure widget — Sightline never sees your bank login.")
                    .font(.system(size: 11)).foregroundStyle(Theme.faint)
            }
        }
        .sheet(isPresented: $showLinkInfo) { LinkAccountSheet() }
    }
}

struct BankCardView: View {
    let account: Account

    private var gradient: [Color] {
        switch account.kind {
        case .debit:   return [Color(hex: "134E42"), Color(hex: "0B3229")]
        case .savings: return [Color(hex: "0E7C66"), Color(hex: "0A5C4C")]
        case .credit:  return [Color(hex: "3A2D5E"), Color(hex: "241A3D")]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("\(account.kind.rawValue.capitalized) · \(account.nickname)")
                    .font(.system(size: 11, weight: .bold)).tracking(1).textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(account.network).font(.system(size: 15, weight: .heavy)).italic().foregroundStyle(.white.opacity(0.95))
            }
            Text(account.maskedNumber).font(Theme.mono(15)).tracking(2)
                .foregroundStyle(.white.opacity(0.92)).padding(.top, 22).padding(.bottom, 14)

            if account.kind == .credit {
                HStack(alignment: .bottom) {
                    cardStat("Owing", Money.aud(account.owing))
                    Spacer()
                    cardStat("Available", Money.aud(account.available), alignment: .trailing)
                }
                Text("Limit \(Money.aud(account.limit)) · \(account.creditPercentUsed)% used")
                    .font(.system(size: 10.5)).foregroundStyle(.white.opacity(0.8)).padding(.top, 8)
            } else {
                cardStat("Balance", Money.aud(account.balance))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        // Glossy highlights so the cards read as physical plastic.
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.08)).frame(width: 170, height: 170).offset(x: 50, y: -70)
        }
        .overlay(alignment: .bottomLeading) {
            Circle().fill(.white.opacity(0.05)).frame(width: 220, height: 220).offset(x: -90, y: 110)
        }
        .overlay(
            LinearGradient(colors: [.white.opacity(0.10), .clear, .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private func cardStat(_ k: String, _ v: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(k).font(.system(size: 10)).foregroundStyle(.white.opacity(0.75))
            Text(v).font(Theme.mono(19)).foregroundStyle(.white)
        }
    }
}

struct LinkAccountSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Screen(title: "Link an account") {
                CardBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(store.isLive ? "Connected to Basiq (live)" : "Using sample data",
                              systemImage: store.isLive ? "checkmark.seal.fill" : "info.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(store.isLive ? Theme.good : Theme.warn)
                        Text("Bank linking opens your bank's secure consent screen through Basiq (Australia's CDR / open-banking network). Sightline receives read-only access to balances and transactions — never your login.")
                            .font(.system(size: 13)).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if AppConfig.bankLinkingEnabled {
                    CardBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To enable live data").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink)
                            stepRow("1", "Run the Sightline proxy in server/ with your Basiq API key")
                            stepRow("2", "Set BackendConfig.baseURL to the proxy URL")
                            stepRow("3", "Flip AppStore.useLiveData to true")
                        }
                    }
                } else {
                    CardBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Coming soon").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink)
                            Text("Live bank connections aren't available in this version yet. Everything you see runs on realistic sample data — budgets, goals and alerts are fully yours to use in the meantime.")
                                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
    private func stepRow(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n).font(.system(size: 12, weight: .heavy)).foregroundStyle(Theme.accentInk)
                .frame(width: 22, height: 22).background(Theme.accentSoft, in: Circle())
            Text(text).font(.system(size: 12.5)).foregroundStyle(Theme.muted)
        }
    }
}
