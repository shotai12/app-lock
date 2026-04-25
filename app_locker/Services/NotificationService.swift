import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Evening Review Notification

    func scheduleEveningNotification(hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["evening.review"]
        )

        let content = UNMutableNotificationContent()
        content.title = "今日の振り返り"
        content.body = "今日のスマホ使用を振り返り、明日の計画を立てましょう。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "evening.review",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Session Warning Banner (30 seconds before timeout)

    func scheduleSessionWarning(sessionEndsAt: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["session.warning"]
        )

        let warningDate = sessionEndsAt.addingTimeInterval(-30)
        guard warningDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "あと30秒で切り替わります"
        content.body = "セッション終了まであと30秒です。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: warningDate.timeIntervalSinceNow,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "session.warning",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelSessionWarning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["session.warning"]
        )
    }

    // MARK: - Reflection Reminder (after screen off)

    func scheduleReflectionReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["reflection.reminder"]
        )

        let content = UNMutableNotificationContent()
        content.title = "使用後の気持ちは？"
        content.body = "スマホを閉じる前にB・C・Dを記録しましょう。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reflection.reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
