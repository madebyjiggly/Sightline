import Foundation
import BackgroundTasks

/// Schedules periodic background wake-ups so the app can pull fresh transactions
/// and fire over-budget alerts even while it's closed. The OS decides exactly
/// when (and whether) to run these, based on usage patterns and battery.
enum BackgroundRefresh {
    static let taskId = "com.sightline.budget.refresh"

    /// Ask the system to wake us again no sooner than ~15 minutes from now.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[Sightline] background refresh scheduled")
        } catch {
            print("[Sightline] background refresh scheduling failed: \(error)")
        }
    }
}
