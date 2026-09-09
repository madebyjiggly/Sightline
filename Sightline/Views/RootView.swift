import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }.tag(1)
            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }.tag(2)
            CardsView()
                .tabItem { Label("Cards", systemImage: "creditcard.fill") }.tag(3)
        }
        .tint(Theme.accent)
        .onChange(of: tab) { _, _ in Haptics.select() }
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
