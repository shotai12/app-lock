import SwiftUI
import SwiftData

struct EveningReviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var sessions: [SessionRecord]

    @State private var planE = ""
    @State private var isSuccessE: Bool? = nil
    @Environment(\.dismiss) private var dismiss

    private var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return logs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var yesterdayLog: DailyLog? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        return logs.first { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }
    }

    private var todayStats: (openCount: Int, avgGuilt: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessions.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        let count = todaySessions.count
        let guilt = todaySessions.compactMap { $0.guiltLevelC }.map(Double.init)
        let avg = guilt.isEmpty ? 0 : guilt.reduce(0, +) / Double(guilt.count)
        return (count, avg)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    summarySection
                    yesterdayGoalSection
                    planSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("E — 夜の振り返り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("今日のサマリー")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(1)

            HStack(spacing: 32) {
                StatBlock(label: "起動回数", value: "\(todayStats.openCount)回")
                StatBlock(label: "平均罪悪感", value: String(format: "%.1f", todayStats.avgGuilt))
            }
        }
    }

    private var yesterdayGoalSection: some View {
        Group {
            if let yesterday = yesterdayLog, let plan = yesterday.planE {
                VStack(alignment: .leading, spacing: 16) {
                    Text("昨日の目標")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    Text(plan)
                        .font(.system(size: 15, weight: .light))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    HStack(spacing: 12) {
                        Text("達成しましたか？")
                            .font(.system(size: 14, weight: .light))
                        Spacer()
                        Button("Yes") { isSuccessE = true }
                            .font(.system(size: 14, weight: .light))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(isSuccessE == true ? Color.primary : Color.clear)
                            .foregroundStyle(isSuccessE == true ? Color(.systemBackground) : Color.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))

                        Button("No") { isSuccessE = false }
                            .font(.system(size: 14, weight: .light))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(isSuccessE == false ? Color.primary : Color.clear)
                            .foregroundStyle(isSuccessE == false ? Color(.systemBackground) : Color.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "E", title: "明日、スマホを開きたくなったら代わりにすることは？")

            TextEditor(text: $planE)
                .font(.system(size: 15, weight: .light))
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
    }

    // MARK: - Actions

    private func save() {
        let today = Calendar.current.startOfDay(for: Date())
        let log: DailyLog
        if let existing = todayLog {
            log = existing
        } else {
            log = DailyLog(date: today)
            context.insert(log)
        }
        log.planE = planE.isEmpty ? nil : planE
        log.isSuccessE = isSuccessE
        log.totalOpenCount = todayStats.openCount
        log.avgGuilt = todayStats.avgGuilt
        try? context.save()
        dismiss()
    }
}

private struct StatBlock: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 28, weight: .ultraLight, design: .rounded))
        }
    }
}
