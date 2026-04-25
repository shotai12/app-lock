import ManagedSettings
import Foundation

// MARK: - Shield Action Extension

class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction,
                          for application: ApplicationToken,
                          completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction,
                          for webDomain: WebDomainToken,
                          completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction,
                          for category: ActivityCategoryToken,
                          completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Action Handling

    private func handleAction(_ action: ShieldAction,
                               completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let sharedData = AppGroupData()
            let count = sharedData.dailyLaunchCount
            let waitSeconds = waitTime(for: count)

            if waitSeconds == 0 {
                // No wait needed: increment count and let the user through
                sharedData.incrementLaunchCount()
                // Record session start timestamp
                sharedData.recordSessionStart()
                // Temporarily remove shield via deep link to main app, then defer
                openMainAppIfNeeded()
                completionHandler(.defer)
            } else {
                // Still waiting: do nothing (wait completed in UI)
                sharedData.incrementLaunchCount()
                sharedData.recordSessionStart()
                openMainAppIfNeeded()
                completionHandler(.defer)
            }

        case .secondaryButtonPressed:
            // "やっぱりやめる" — close without incrementing count
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func openMainAppIfNeeded() {
        // Open main app via URL scheme to sync state if needed
        // Actual redirect to applocker:// happens from DeviceActivity extension on timeout
    }

    private func waitTime(for count: Int) -> Int {
        switch count {
        case 1...3:   return 0
        case 4...6:   return 5
        case 7...10:  return 15
        case 11...15: return 30
        case 16...20: return 60
        case 21...30: return 180
        default:      return 600
        }
    }
}

// MARK: - Shared App Group Data Writer

private class AppGroupData {
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: "group.com.applockteam.applockershared") ?? .standard
    }

    var dailyLaunchCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset = defaults.object(forKey: "lastResetDate") as? Date
        if lastReset == nil || lastReset! < today {
            return 0
        }
        return defaults.integer(forKey: "dailyLaunchCount")
    }

    func incrementLaunchCount() {
        let current = dailyLaunchCount
        let today = Calendar.current.startOfDay(for: Date())
        defaults.set(today, forKey: "lastResetDate")
        defaults.set(current + 1, forKey: "dailyLaunchCount")
    }

    func recordSessionStart() {
        defaults.set(Date(), forKey: "sessionStartTimestamp")
    }
}
