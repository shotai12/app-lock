import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    private let sharedData = SharedDataService.shared

    @Published var isAuthorized = false
    @Published var selection = FamilyActivitySelection()

    private init() {
        selection = sharedData.loadFamilyActivitySelection()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run { isAuthorized = true }
        } catch {
            print("[AppLockService] Authorization error: \(error)")
        }
    }

    // MARK: - Shield Management

    func applyShields() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        sharedData.isShieldingEnabled = true
    }

    func removeShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        sharedData.isShieldingEnabled = false
    }

    func updateSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        sharedData.saveFamilyActivitySelection(newSelection)
        if sharedData.isShieldingEnabled {
            applyShields()
        }
    }

    // MARK: - Session Monitoring (DeviceActivity)

    func startSessionMonitoring(durationMinutes: Int) {
        let sessionName = DeviceActivityName("com.applockteam.applocksession")
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true,
            warningTime: DateComponents(second: 30)
        )

        // Monitor individual app usage
        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            .sessionTimeout: DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                threshold: DateComponents(minute: durationMinutes)
            )
        ]

        do {
            try deviceActivityCenter.startMonitoring(sessionName, during: schedule, events: events)
            sharedData.startSession()
        } catch {
            print("[AppLockService] Monitoring error: \(error)")
        }
    }

    func stopSessionMonitoring() {
        let sessionName = DeviceActivityName("com.applockteam.applocksession")
        deviceActivityCenter.stopMonitoring([sessionName])
        sharedData.clearSession()
    }
}

extension DeviceActivityEvent.Name {
    static let sessionTimeout = DeviceActivityEvent.Name("sessionTimeout")
}
