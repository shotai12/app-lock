import SwiftUI
import SwiftData
import Combine

@MainActor
final class ModeBViewModel: ObservableObject {
    @Published var phase: ModeBPhase = .idle
    @Published var sessionSecondsRemaining: Int = 0
    @Published var currentSession: SessionRecord?
    @Published var skipCount: Int = 0

    private var sessionTimer: AnyCancellable?

    let sharedData = SharedDataService.shared
    let lockService = AppLockService.shared
    let notificationService = NotificationService.shared

    // Default trigger options (A)
    let defaultTriggers: [String] = [
        "暇つぶし", "現実逃避", "情報収集", "連絡確認", "仕事・勉強", "寝る前のルーティン", "習慣（無意識）"
    ]

    // Default belief options (B)
    let defaultBeliefs: [String] = [
        "つい開いてしまった", "一瞬だけと思った", "これくらいはいい", "不安を紛らわしたかった", "ご褒美感覚"
    ]

    // Default dispute options (D)
    let defaultDisputes: [String] = [
        "代わりに本を読む", "散歩に出る", "深呼吸を3回する", "水を飲む", "ノートに気持ちを書く", "筋トレする"
    ]

    enum ModeBPhase {
        case idle
        case triggerRecording
        case sessionActive
        case reflectionRecording
        case done
    }

    // MARK: - Flow Control

    func startFlow(context: ModelContext) {
        let session = SessionRecord(appBundleID: "", endReason: .manual)
        context.insert(session)
        currentSession = session
        phase = .triggerRecording
    }

    func recordTrigger(_ trigger: String?, context: ModelContext) {
        currentSession?.triggerA = trigger
        if trigger == nil { skipCount += 1 }
        try? context.save()
        beginSession()
    }

    func skipTrigger() {
        skipCount += 1
        beginSession()
    }

    private func beginSession() {
        let durationSeconds = sharedData.sessionDurationMinutes * 60
        sessionSecondsRemaining = durationSeconds
        phase = .sessionActive

        let sessionEndTime = Date().addingTimeInterval(TimeInterval(durationSeconds))
        notificationService.scheduleSessionWarning(sessionEndsAt: sessionEndTime)
        sharedData.startSession()

        sessionTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.sessionSecondsRemaining > 1 {
                    self.sessionSecondsRemaining -= 1
                } else {
                    self.sessionTimer?.cancel()
                    self.handleSessionTimeout()
                }
            }
    }

    private func handleSessionTimeout() {
        notificationService.cancelSessionWarning()
        sharedData.clearSession()
        sharedData.incrementLaunchCount()

        if let session = currentSession {
            session.endReasonRaw = EndReason.timeout.rawValue
        }
        phase = .reflectionRecording
    }

    func endSessionManually() {
        sessionTimer?.cancel()
        notificationService.cancelSessionWarning()
        sharedData.clearSession()

        if let session = currentSession {
            session.duration = TimeInterval(sharedData.sessionDurationMinutes * 60 - sessionSecondsRemaining)
        }
        phase = .reflectionRecording
    }

    func recordReflection(belief: String?, guiltLevel: Int, dispute: String?, context: ModelContext) {
        guard let session = currentSession else { return }
        session.beliefB = belief
        session.guiltLevelC = guiltLevel
        session.disputeD = dispute
        session.isCompleted = true
        try? context.save()
        phase = .done
    }

    func skipReflection(context: ModelContext) {
        currentSession?.isCompleted = true
        try? context.save()
        phase = .done
    }

    func reset() {
        sessionTimer?.cancel()
        currentSession = nil
        phase = .idle
        sessionSecondsRemaining = 0
    }

    // MARK: - Helpers

    var sessionTimeFormatted: String {
        let m = sessionSecondsRemaining / 60
        let s = sessionSecondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var sessionProgressFraction: Double {
        let total = Double(sharedData.sessionDurationMinutes * 60)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(sessionSecondsRemaining) / total)
    }

    var elapsedMinutes: Int {
        let elapsed = sharedData.sessionDurationMinutes * 60 - sessionSecondsRemaining
        return elapsed / 60
    }
}
