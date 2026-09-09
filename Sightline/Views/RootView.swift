import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: AppTab = .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tag(AppTab.home)
                .toolbar(.hidden, for: .tabBar)
            CalendarView()
                .tag(AppTab.calendar)
                .toolbar(.hidden, for: .tabBar)
            GoalsView()
                .tag(AppTab.goals)
                .toolbar(.hidden, for: .tabBar)
            CardsView()
                .tag(AppTab.cards)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(Theme.accent)
        // Our own floating bar; safeAreaInset keeps content from scrolling under it.
        .safeAreaInset(edge: .bottom) { FloatingTabBar(selection: $tab) }
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
