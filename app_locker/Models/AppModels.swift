import SwiftData
import Foundation

// MARK: - Enums

enum ModeType: String, Codable, CaseIterable {
    case modeA = "A"
    case modeB = "B"

    var displayName: String {
        switch self {
        case .modeA: return "Heavy Lock Mode"
        case .modeB: return "Reflection Mode"
        }
    }

    var description: String {
        switch self {
        case .modeA: return "高依存度向け。制限アプリへの起動回数に応じた待機時間でスマホ依存を抑制します。"
        case .modeB: return "中・低依存度向け。ABCDE日記で無意識の衝動を意識的な選択へ変容させます。"
        }
    }
}

enum EndReason: String, Codable {
    case timeout = "timeout"
    case manual = "manual"
}

enum OptionCategory: String, Codable, CaseIterable {
    case triggerA = "A"
    case beliefB = "B"
    case disputeD = "D"

    var label: String {
        switch self {
        case .triggerA: return "きっかけ（A）"
        case .beliefB: return "自動思考（B）"
        case .disputeD: return "反論（D）"
        }
    }
}

// MARK: - SwiftData Models

@Model
final class SessionRecord {
    var id: UUID
    var timestamp: Date
    var appBundleID: String
    var duration: TimeInterval
    var triggerA: String?
    var beliefB: String?
    var guiltLevelC: Int?
    var disputeD: String?
    var planE: String?
    var isCompleted: Bool
    var endReasonRaw: String

    var endReason: EndReason {
        get { EndReason(rawValue: endReasonRaw) ?? .manual }
        set { endReasonRaw = newValue.rawValue }
    }

    init(appBundleID: String = "", endReason: EndReason = .manual) {
        self.id = UUID()
        self.timestamp = Date()
        self.appBundleID = appBundleID
        self.duration = 0
        self.isCompleted = false
        self.endReasonRaw = endReason.rawValue
    }
}

@Model
final class CustomOption {
    var id: UUID
    var categoryRaw: String
    var content: String
    var usageCount: Int
    var createdAt: Date

    var category: OptionCategory {
        get { OptionCategory(rawValue: categoryRaw) ?? .triggerA }
        set { categoryRaw = newValue.rawValue }
    }

    init(category: OptionCategory, content: String) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
        self.content = content
        self.usageCount = 0
        self.createdAt = Date()
    }
}

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var totalOpenCount: Int
    var totalDuration: TimeInterval
    var avgGuilt: Double
    var planE: String?
    var isSuccessE: Bool?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.totalOpenCount = 0
        self.totalDuration = 0
        self.avgGuilt = 0
    }
}

@Model
final class DailyAppStat {
    var id: UUID
    var date: Date
    var appBundleID: String
    var openCount: Int
    var cumulativeTime: TimeInterval

    init(date: Date = Date(), appBundleID: String) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.appBundleID = appBundleID
        self.openCount = 0
        self.cumulativeTime = 0
    }
}

@Model
final class AppSettings {
    var sessionDurationMinutes: Int
    var modeTypeRaw: String
    var nightNotificationHour: Int
    var nightNotificationMinute: Int
    var isOnboardingComplete: Bool
    var pendingSessionDurationMinutes: Int?
    var pendingSessionChangeDate: Date?

    var modeType: ModeType {
        get { ModeType(rawValue: modeTypeRaw) ?? .modeA }
        set { modeTypeRaw = newValue.rawValue }
    }

    var effectiveSessionDuration: Int {
        let today = Calendar.current.startOfDay(for: Date())
        if let pendingDate = pendingSessionChangeDate,
           let pending = pendingSessionDurationMinutes,
           today >= pendingDate {
            return pending
        }
        return sessionDurationMinutes
    }

    init() {
        self.sessionDurationMinutes = 5
        self.modeTypeRaw = ModeType.modeA.rawValue
        self.nightNotificationHour = 22
        self.nightNotificationMinute = 0
        self.isOnboardingComplete = false
    }
}
