import SwiftUI
import SwiftData

struct CalendarHeatmapView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var sessions: [SessionRecord]
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]

    @State private var selectedDate: Date?
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                monthNavigator
                weekdayHeader
                calendarGrid
                if let date = selectedDate {
                    DayDetailView(date: date, sessions: sessionsForDate(date))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .light))
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.year().month())
                .font(.system(size: 16, weight: .light))
            Spacer()
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .light))
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth(displayedMonth)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    CalendarCell(
                        date: date,
                        count: openCountForDate(date),
                        maxCount: maxDailyCount,
                        isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                        isToday: Calendar.current.isDateInToday(date)
                    )
                    .onTapGesture { selectedDate = date }
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Helpers

    private func daysInMonth(_ month: Date) -> [Date?] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: month),
              let firstDay = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month))
        else { return [] }

        let weekday = Calendar.current.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            days.append(Calendar.current.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return days
    }

    private func openCountForDate(_ date: Date) -> Int {
        sessions.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }.count
    }

    private func sessionsForDate(_ date: Date) -> [SessionRecord] {
        sessions.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }

    private var maxDailyCount: Int {
        guard !sessions.isEmpty else { return 1 }
        let grouped = Dictionary(grouping: sessions) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }
        return grouped.values.map(\.count).max() ?? 1
    }
}

// MARK: - Calendar Cell

private struct CalendarCell: View {
    let date: Date
    let count: Int
    let maxCount: Int
    let isSelected: Bool
    let isToday: Bool

    private var intensity: Double {
        guard maxCount > 0 else { return 0 }
        return min(Double(count) / Double(maxCount), 1.0)
    }

    private var cellColor: Color {
        if count == 0 { return Color.primary.opacity(0.04) }
        return Color.indigo.opacity(0.15 + intensity * 0.65)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary : cellColor)
                .aspectRatio(1, contentMode: .fit)

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 12, weight: isToday ? .medium : .light))
                .foregroundStyle(isSelected ? Color(.systemBackground) : (count > 0 ? Color.primary : Color.secondary))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isToday ? Color.primary.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Day Detail

private struct DayDetailView: View {
    let date: Date
    let sessions: [SessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(date, style: .date)
                    .font(.system(size: 14, weight: .light))
                Spacer()
                Text("\(sessions.count)回")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.secondary)
            }

            if sessions.isEmpty {
                Text("記録なし")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(sessions) { session in
                    DiaryRow(session: session)
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
