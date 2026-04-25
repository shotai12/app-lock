import SwiftUI
import SwiftData
import FamilyControls

@MainActor
final class AppViewModel: ObservableObject {
    @Published var isOnboardingComplete: Bool = false
    @Published var currentMode: ModeType = .modeA
    @Published var showingDiaryEntry: Bool = false
    @Published var pendingDiarySession: SessionRecord?

    let lockService = AppLockService.shared
    let notificationService = NotificationService.shared
    let sharedData = SharedDataService.shared

    private var settings: AppSettings?

    func bootstrap(settings: AppSettings?) {
        self.settings = settings
        if let s = settings {
            isOnboardingComplete = s.isOnboardingComplete
            currentMode = s.modeType
            sharedData.modeType = s.modeType.rawValue
            sharedData.sessionDurationMinutes = s.effectiveSessionDuration

            notificationService.scheduleEveningNotification(
                hour: s.nightNotificationHour,
                minute: s.nightNotificationMinute
            )
        }
    }

    func completeOnboarding(mode: ModeType, sessionMinutes: Int, settings: AppSettings, context: ModelContext) {
        settings.modeType = mode
        settings.sessionDurationMinutes = sessionMinutes
        settings.isOnboardingComplete = true

        sharedData.modeType = mode.rawValue
        sharedData.sessionDurationMinutes = sessionMinutes

        isOnboardingComplete = true
        currentMode = mode

        try? context.save()
        lockService.applyShields()
    }

    func switchMode(to mode: ModeType, settings: AppSettings, context: ModelContext) {
        settings.modeType = mode
        currentMode = mode
        sharedData.modeType = mode.rawValue
        try? context.save()
    }

    func handleDeepLink(_ url: URL, context: ModelContext) {
        guard url.scheme == "applocker" else { return }
        let newSession = SessionRecord(appBundleID: "", endReason: .timeout)
        context.insert(newSession)
        pendingDiarySession = newSession
        showingDiaryEntry = true
    }
}
