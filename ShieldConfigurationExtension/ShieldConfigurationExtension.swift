import ManagedSettings
import ManagedSettingsUI
import SwiftUI

// MARK: - Extension Entry Point

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        shieldConfiguration(name: application.localizedDisplayName ?? "このアプリ")
    }

    override func configuration(shielding application: Application,
                                 in category: ActivityCategory) -> ShieldConfiguration {
        shieldConfiguration(name: application.localizedDisplayName ?? "このアプリ")
    }

    override func configuration(shielding category: ActivityCategory) -> ShieldConfiguration {
        shieldConfiguration(name: "このカテゴリのアプリ")
    }

    // MARK: - Build ShieldConfiguration

    private func shieldConfiguration(name: String) -> ShieldConfiguration {
        let sharedData = AppGroupData()
        let count = sharedData.dailyLaunchCount
        let waitSeconds = waitTime(for: count)

        let title = ShieldConfiguration.Label(
            text: waitSeconds > 0 ? "少し待ってください" : "開く前に一息",
            color: .label
        )

        let subtitle = ShieldConfiguration.Label(
            text: waitSeconds > 0
                ? "今日\(count)回目。\(formatWait(waitSeconds))後に開けます。"
                : "\(name)を開こうとしています",
            color: .secondaryLabel
        )

        let primaryButton = ShieldConfiguration.Label(
            text: waitSeconds > 0 ? "\(formatWait(waitSeconds))待つ" : "開く",
            color: .systemBackground
        )
        let primaryButtonBg = UIColor.label

        let secondaryButton = ShieldConfiguration.Label(
            text: "やっぱりやめる",
            color: .secondaryLabel
        )

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: nil,
            icon: nil,
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: primaryButton,
            primaryButtonBackgroundColor: primaryButtonBg,
            secondaryButtonLabel: secondaryButton
        )
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

    private func formatWait(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)秒" }
        return "\(seconds / 60)分"
    }
}

// MARK: - Shared App Group Data Reader

private struct AppGroupData {
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: "group.com.applockteam.applockershared") ?? .standard
    }

    var dailyLaunchCount: Int {
        // Reset if new day
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset = defaults.object(forKey: "lastResetDate") as? Date
        if lastReset == nil || lastReset! < today {
            return 0
        }
        return defaults.integer(forKey: "dailyLaunchCount")
    }
}
