import SwiftUI
import SwiftData

struct DiaryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var sessions: [SessionRecord]

    @State private var selectedSession: SessionRecord?
    @State private var showingEveningReview = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode { case list, calendar }

    private var completedSessions: [SessionRecord] {
        sessions.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewMode {
                case .list:  listView
                case .calendar: CalendarHeatmapView()
                }
            }
            .navigationTitle("日記")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("表示", selection: $viewMode) {
                        Image(systemName: "list.bullet").tag(ViewMode.list)
                        Image(systemName: "calendar").tag(ViewMode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 88)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEveningReview = true
                    } label: {
                        Image(systemName: "moon.stars")
                    }
                }
            }
            .sheet(item: $selectedSession) { session in
                DiaryEntryView(session: session) {
                    selectedSession = nil
                }
            }
            .sheet(isPresented: $showingEveningReview) {
                EveningReviewView()
            }
        }
    }

    // MARK: - List View

    private var listView: some View {
        Group {
            if completedSessions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                        Section(header: dateHeader(date)) {
                            ForEach(groupedByDate[date] ?? []) { session in
                                DiaryRow(session: session)
                                    .onTapGesture { selectedSession = session }
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("記録がまだありません")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.secondary)
            Text("スマホを使った後にABCDE日記を書きましょう")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var groupedByDate: [Date: [SessionRecord]] {
        Dictionary(grouping: completedSessions) { session in
            Calendar.current.startOfDay(for: session.timestamp)
        }
    }

    private func dateHeader(_ date: Date) -> some View {
        Text(date, style: .date)
            .font(.system(size: 12, weight: .light))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }
}

// MARK: - Diary Row

struct DiaryRow: View {
    let session: SessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.timestamp, style: .time)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.secondary)
                Spacer()
                if let guilt = session.guiltLevelC {
                    GuiltBadge(level: guilt)
                }
                EndReasonBadge(reason: session.endReason)
            }

            if let a = session.triggerA {
                LabeledText(label: "A", text: a)
            }
            if let b = session.beliefB {
                LabeledText(label: "B", text: b)
            }
            if let d = session.disputeD {
                LabeledText(label: "D", text: d)
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct LabeledText: View {
    let label: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(1)
                .frame(width: 14)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 13, weight: .light))
                .lineLimit(2)
        }
    }
}

private struct GuiltBadge: View {
    let level: Int

    private var color: Color {
        let f = Double(level - 1) / 9
        return Color(red: f, green: 0.3, blue: 1 - f)
    }

    var body: some View {
        Text("\(level)")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay(
                Capsule().stroke(color.opacity(0.4), lineWidth: 1)
            )
    }
}

private struct EndReasonBadge: View {
    let reason: EndReason

    var body: some View {
        if reason == .timeout {
            Text("TO")
                .font(.system(size: 9, weight: .light))
                .foregroundStyle(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 1))
        }
    }
}
