import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }
            CardsView()
                .tabItem { Label("Cards", systemImage: "creditcard.fill") }
        }
        .tint(Theme.accent)
    }
}

// A compact source badge shown at the top of Home.
struct SourceBadge: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(store.isLive ? Theme.good : Theme.warn).frame(width: 7, height: 7)
            Text(store.isLive ? "Live" : "Sample")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Theme.surface2, in: Capsule())
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}
