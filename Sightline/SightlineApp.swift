import SwiftUI
import SwiftData

@main
struct SightlineApp: App {
    let container: ModelContainer
    @StateObject private var store: AppStore
    @StateObject private var theme = ThemeManager()
    @StateObject private var auth = AuthManager.shared
    @StateObject private var streak = StreakManager.shared
    private let notifier = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let schema = Schema([BudgetItem.self, GoalItem.self])
        let config = ModelConfiguration(schema: schema)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Schema changed during development — reset the local store and retry
            // so a model change never bricks the app on launch.
            try? FileManager.default.removeItem(at: config.url)
            container = (try? ModelContainer(for: schema, configurations: config))
                ?? {
                    let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    return try! ModelContainer(for: schema, configurations: mem)
                }()
        }
        self.container = container
        _store = StateObject(wrappedValue: AppStore(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifier)
                .environmentObject(theme)
                .environmentObject(auth)
                .environmentObject(streak)
                .tint(Theme.accent)
                .preferredColorScheme(theme.mode.colorScheme)
                .task {
                    await store.load()
                    streak.recordVisit()
                    BackgroundRefresh.schedule()
                }
        }
        .modelContainer(container)
        // Registers the handler that runs when the OS wakes the app in the background.
        .backgroundTask(.appRefresh(BackgroundRefresh.taskId)) {
            await store.load()          // pull fresh data + evaluate over-budget alerts
            BackgroundRefresh.schedule() // chain the next wake-up
        }
        // Re-arm a wake-up whenever the app is sent to the background.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { BackgroundRefresh.schedule() }
            if phase == .active { streak.recordVisit() }
        }
    }
}
