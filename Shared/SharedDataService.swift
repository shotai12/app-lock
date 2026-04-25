import Foundation
import FamilyControls

// App Group identifier shared across all targets
let appGroupID = "group.com.applockteam.applockershared"

// UserDefaults keys
enum SharedKeys {
    static let dailyLaunchCount = "dailyLaunchCount"
    static let lastResetDate = "lastResetDate"
    static let sessionDurationMinutes = "sessionDurationMinutes"
    static let modeType = "modeType"
    static let isShieldingEnabled = "isShieldingEnabled"
    static let sessionStartTimestamp = "sessionStartTimestamp"
    static let familyActivitySelectionData = "familyActivitySelectionData"
    static let pendingCancelCount = "pendingCancelCount"
}

final class SharedDataService {
    static let shared = SharedDataService()

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Daily Launch Count

    var dailyLaunchCount: Int {
        get {
            resetIfNeeded()
            return defaults.integer(forKey: SharedKeys.dailyLaunchCount)
        }
        set {
            defaults.set(newValue, forKey: SharedKeys.dailyLaunchCount)
        }
    }

    func incrementLaunchCount() {
        dailyLaunchCount += 1
    }

    private func resetIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset = defaults.object(forKey: SharedKeys.lastResetDate) as? Date
        if lastReset == nil || lastReset! < today {
            defaults.set(0, forKey: SharedKeys.dailyLaunchCount)
            defaults.set(today, forKey: SharedKeys.lastResetDate)
        }
    }

    // MARK: - Wait Time Calculation

    func waitTimeSeconds(for count: Int) -> Int {
        switch count {
        case 1...3:   return 0
        case 4...6:   return 5
        case 7...10:  return 15
        case 11...15: return 30
        case 16...20: return 60
        case 21...30: return 180
        default:      return 600 // 31回以上は10分固定
        }
    }

    // MARK: - Session Settings

    var sessionDurationMinutes: Int {
        get { defaults.integer(forKey: SharedKeys.sessionDurationMinutes).nonZero ?? 5 }
        set { defaults.set(newValue, forKey: SharedKeys.sessionDurationMinutes) }
    }

    var modeType: String {
        get { defaults.string(forKey: SharedKeys.modeType) ?? "A" }
        set { defaults.set(newValue, forKey: SharedKeys.modeType) }
    }

    var isShieldingEnabled: Bool {
        get { defaults.bool(forKey: SharedKeys.isShieldingEnabled) }
        set { defaults.set(newValue, forKey: SharedKeys.isShieldingEnabled) }
    }

    // MARK: - Session Timing

    var sessionStartTimestamp: Date? {
        get { defaults.object(forKey: SharedKeys.sessionStartTimestamp) as? Date }
        set { defaults.set(newValue, forKey: SharedKeys.sessionStartTimestamp) }
    }

    func startSession() {
        sessionStartTimestamp = Date()
    }

    func clearSession() {
        sessionStartTimestamp = nil
    }

    // MARK: - FamilyActivitySelection

    var familyActivitySelectionData: Data? {
        get { defaults.data(forKey: SharedKeys.familyActivitySelectionData) }
        set { defaults.set(newValue, forKey: SharedKeys.familyActivitySelectionData) }
    }

    func saveFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        let data = try? JSONEncoder().encode(selection)
        familyActivitySelectionData = data
    }

    func loadFamilyActivitySelection() -> FamilyActivitySelection {
        guard let data = familyActivitySelectionData,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
