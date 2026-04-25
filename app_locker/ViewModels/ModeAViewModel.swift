import SwiftUI
import SwiftData
import Combine

@MainActor
final class ModeAViewModel: ObservableObject {
    @Published var phase: ModeAPhase = .idle
    @Published var waitSecondsRemaining: Int = 0
    @Published var sessionSecondsRemaining: Int = 0
    @Published var dailyLaunchCount: Int = 0

    private var waitTimer: AnyCancellable?
    private var sessionTimer: AnyCancellable?

    let sharedData = SharedDataService.shared
    let lockService = AppLockService.shared
    let notificationService = NotificationService.shared

    enum ModeAPhase {
        case idle
        case waiting
        case sessionActive
        case sessionEnded
    }

    // MARK: - Wait Phase

    func beginWaitPhase() {
        let count = sharedData.dailyLaunchCount + 1
        dailyLaunchCount = count
        let waitTime = sharedData.waitTimeSeconds(for: count)

        if waitTime == 0 {
            beginSession()
            return
        }

        phase = .waiting
        waitSecondsRemaining = waitTime

        waitTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.waitSecondsRemaining > 1 {
                    self.waitSecondsRemaining -= 1
                } else {
                    self.waitTimer?.cancel()
                    self.beginSession()
                }
            }
    }

    func cancelWait() {
        waitTimer?.cancel()
        phase = .idle
    }

    // MARK: - Session Phase

    private func beginSession() {
        sharedData.incrementLaunchCount()
        dailyLaunchCount = sharedData.dailyLaunchCount

        let durationSeconds = sharedData.sessionDurationMinutes * 60
        sessionSecondsRemaining = durationSeconds
        phase = .sessionActive

        let sessionEndTime = Date().addingTimeInterval(TimeInterval(durationSeconds))
        notificationService.scheduleSessionWarning(sessionEndsAt: sessionEndTime)
        sharedData.startSession()

        lockService.removeShields()

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
        lockService.applyShields()
        phase = .sessionEnded
    }

    func endSessionManually() {
        sessionTimer?.cancel()
        notificationService.cancelSessionWarning()
        sharedData.clearSession()
        lockService.applyShields()
        phase = .idle
    }

    // MARK: - Helpers

    var waitTimeFormatted: String {
        formatTime(waitSecondsRemaining)
    }

    var sessionTimeFormatted: String {
        formatTime(sessionSecondsRemaining)
    }

    var waitProgressFraction: Double {
        let count = dailyLaunchCount
        let total = Double(sharedData.waitTimeSeconds(for: count))
        guard total > 0 else { return 1.0 }
        return 1.0 - (Double(waitSecondsRemaining) / total)
    }

    var sessionProgressFraction: Double {
        let total = Double(sharedData.sessionDurationMinutes * 60)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(sessionSecondsRemaining) / total)
    }

    var waitTimeLabel: String {
        let count = dailyLaunchCount
        let seconds = sharedData.waitTimeSeconds(for: count)
        switch seconds {
        case 0:    return "制限なし"
        case 5:    return "5秒"
        case 15:   return "15秒"
        case 30:   return "30秒"
        case 60:   return "1分"
        case 180:  return "3分"
        default:   return "10分"
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        if m > 0 {
            return String(format: "%d:%02d", m, s)
        } else {
            return "\(s)"
        }
    }
}
