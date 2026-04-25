import DeviceActivity
import ManagedSettings
import Foundation

// MARK: - Device Activity Monitor Extension

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private let defaults = UserDefaults(suiteName: "group.com.applockteam.applockershared") ?? .standard

    // Called 30 seconds before session threshold (warningTime)
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        scheduleSessionWarningNotification()
    }

    // Called when a per-app usage threshold is hit (sessionTimeout event)
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                          activity: DeviceActivityName) {
        if event == .sessionTimeout {
            handleSessionTimeout()
        }
    }

    // Called when the monitored interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Re-apply shields at the end of interval
        applyShields()
    }

    // MARK: - Session Timeout

    private func handleSessionTimeout() {
        // Increment launch count (timeout counts as a launch)
        incrementLaunchCount()
        // Re-apply shields immediately
        applyShields()
        // Clear session start time
        defaults.removeObject(forKey: "sessionStartTimestamp")
        // Notify user via local notification to open App Locker
        scheduleTimeoutNotification()
    }

    private func applyShields() {
        guard let data = defaults.data(forKey: "familyActivitySelectionData"),
              let selection = try? JSONDecoder().decode(ShieldableSelection.self, from: data)
        else { return }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    private func incrementLaunchCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset = defaults.object(forKey: "lastResetDate") as? Date
        var current = 0
        if let lastReset, lastReset >= today {
            current = defaults.integer(forKey: "dailyLaunchCount")
        }
        defaults.set(today, forKey: "lastResetDate")
        defaults.set(current + 1, forKey: "dailyLaunchCount")
    }

    // MARK: - Notifications

    private func scheduleSessionWarningNotification() {
        // Warning notification is already scheduled by NotificationService in the main app.
        // This serves as a fallback.
    }

    private func scheduleTimeoutNotification() {
        let content = UNMutableNotificationContent()
        content.title = "セッション終了"
        content.body = "App Lockerで気持ちを記録しましょう。"
        content.sound = .default
        // Deep link to main app on tap
        content.userInfo = ["url": "applocker://timeout"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "session.timeout",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

import UserNotifications

// MARK: - Minimal Codable wrapper to decode FamilyActivitySelection tokens
// (FamilyActivitySelection itself is Codable; this just aliases it for clarity)

private struct ShieldableSelection: Codable {
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
}

extension DeviceActivityEvent.Name {
    static let sessionTimeout = DeviceActivityEvent.Name("sessionTimeout")
}
