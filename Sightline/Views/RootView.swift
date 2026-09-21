import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: AppTab = .home

    var body: some View {
        TabView(selection: $tab) {
            tabRoot(HomeView()).tag(AppTab.home)
            tabRoot(CalendarView()).tag(AppTab.calendar)
            tabRoot(GoalsView()).tag(AppTab.goals)
            tabRoot(CardsView()).tag(AppTab.cards)
        }
        .tint(Theme.accent)
        // Our own floating bar. It is drawn as an overlay; each tab root gets a
        // matching bottom safe-area spacer (a safeAreaInset on the TabView itself
        // does NOT propagate into the tabs' scroll views on device, which let
        // content hide underneath the bar).
        .overlay(alignment: .bottom) { FloatingTabBar(selection: $tab) }
        .onChange(of: tab) { _, _ in Haptics.select() }
    }

    /// Hides the system tab bar and reserves scroll space for the floating one.
    private func tabRoot<V: View>(_ view: V) -> some View {
        view
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: FloatingTabBar.reservedHeight)
            }
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
