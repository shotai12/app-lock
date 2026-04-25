import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Query(sort: \SessionRecord.timestamp, order: .reverse) private var sessions: [SessionRecord]
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]

    @State private var span: Span = .week

    enum Span: String, CaseIterable {
        case week = "週"
        case month = "月"
        case year = "年"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    spanPicker
                    launchCountChart
                    guiltTrendChart
                    heatmapSection
                    bubbleChartSection
                    insightSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("レポート")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Span Picker

    private var spanPicker: some View {
        Picker("期間", selection: $span) {
            ForEach(Span.allCases, id: \.self) { s in
                Text(s.rawValue).tag(s)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Launch Count Line Chart

    private var launchCountChart: some View {
        ChartCard(title: "起動回数の推移") {
            Chart(launchData) { item in
                LineMark(
                    x: .value("日付", item.date),
                    y: .value("回数", item.count)
                )
                .foregroundStyle(Color.indigo.opacity(0.7))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("日付", item.date),
                    y: .value("回数", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.15), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: xStride)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.1))
                    AxisValueLabel(format: xFormat)
                        .font(.system(size: 10, weight: .light))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.1))
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .light))
                }
            }
            .frame(height: 180)
        }
    }

    // MARK: - Guilt Trend Chart

    private var guiltTrendChart: some View {
        ChartCard(title: "罪悪感スコアの推移") {
            Chart(guiltData) { item in
                LineMark(
                    x: .value("日付", item.date),
                    y: .value("罪悪感", item.avgGuilt)
                )
                .foregroundStyle(Color.red.opacity(0.5))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("日付", item.date),
                    y: .value("罪悪感", item.avgGuilt)
                )
                .foregroundStyle(Color.red.opacity(0.6))
                .symbolSize(30)
            }
            .chartYScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: .stride(by: xStride)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.1))
                    AxisValueLabel(format: xFormat)
                        .font(.system(size: 10, weight: .light))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.1))
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .light))
                }
            }
            .frame(height: 160)
        }
    }

    // MARK: - Heatmap: Trigger × TimeOfDay

    private var heatmapSection: some View {
        ChartCard(title: "きっかけ × 時間帯 ヒートマップ") {
            if heatmapData.isEmpty {
                emptyChartPlaceholder
            } else {
                HeatmapChart(data: heatmapData)
                    .frame(height: max(CGFloat(heatmapData.keys.count) * 40, 120))
            }
        }
    }

    // MARK: - Bubble Chart

    private var bubbleChartSection: some View {
        ChartCard(title: "時間泥棒バブルチャート") {
            if bubbleData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(bubbleData) { item in
                    PointMark(
                        x: .value("平均時間(分)", item.avgMinutes),
                        y: .value("罪悪感", item.avgGuilt)
                    )
                    .symbolSize(CGFloat(item.openCount) * 20)
                    .foregroundStyle(Color.purple.opacity(0.4))
                    .annotation(position: .top) {
                        Text(item.trigger)
                            .font(.system(size: 9, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxisLabel("平均使用時間（分）", alignment: .center)
                .chartYAxisLabel("罪悪感", alignment: .center)
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.primary.opacity(0.1))
                        AxisValueLabel()
                            .font(.system(size: 10, weight: .light))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.primary.opacity(0.1))
                        AxisValueLabel()
                            .font(.system(size: 10, weight: .light))
                    }
                }
                .frame(height: 220)
            }
        }
    }

    // MARK: - Auto Insights

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自動インサイト")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(1)

            if autoInsights.isEmpty {
                Text("データが蓄積されるとインサイトが表示されます")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.tertiary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(autoInsights, id: \.self) { insight in
                    InsightCard(text: insight)
                }
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        Text("記録が増えると表示されます")
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    // MARK: - Data Computation

    private var filteredSessions: [SessionRecord] {
        let cutoff = cutoffDate
        return sessions.filter { $0.timestamp >= cutoff }
    }

    private var cutoffDate: Date {
        let cal = Calendar.current
        switch span {
        case .week:  return cal.date(byAdding: .day,   value: -7,  to: Date()) ?? Date()
        case .month: return cal.date(byAdding: .month, value: -1,  to: Date()) ?? Date()
        case .year:  return cal.date(byAdding: .year,  value: -1,  to: Date()) ?? Date()
        }
    }

    private var xStride: Calendar.Component {
        switch span {
        case .week:  return .day
        case .month: return .weekOfMonth
        case .year:  return .month
        }
    }

    private var xFormat: Date.FormatStyle {
        switch span {
        case .week:  return .dateTime.month(.twoDigits).day(.twoDigits)
        case .month: return .dateTime.month(.twoDigits).day(.twoDigits)
        case .year:  return .dateTime.month(.abbreviated)
        }
    }

    struct DailyCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    struct DailyGuilt: Identifiable {
        let id = UUID()
        let date: Date
        let avgGuilt: Double
    }

    struct BubbleItem: Identifiable {
        let id = UUID()
        let trigger: String
        let avgMinutes: Double
        let avgGuilt: Double
        let openCount: Int
    }

    private var launchData: [DailyCount] {
        let grouped = Dictionary(grouping: filteredSessions) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }
        return grouped.map { DailyCount(date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    private var guiltData: [DailyGuilt] {
        let grouped = Dictionary(grouping: filteredSessions.filter { $0.guiltLevelC != nil }) {
            Calendar.current.startOfDay(for: $0.timestamp)
        }
        return grouped.map { entry -> DailyGuilt in
            let avg = entry.value.compactMap { $0.guiltLevelC }.map(Double.init).reduce(0, +)
                / Double(entry.value.count)
            return DailyGuilt(date: entry.key, avgGuilt: avg)
        }
        .sorted { $0.date < $1.date }
    }

    // trigger (A) × hour-of-day → avg guilt
    private var heatmapData: [String: [HeatmapCell]] {
        let withTrigger = filteredSessions.filter { $0.triggerA != nil && $0.guiltLevelC != nil }
        guard !withTrigger.isEmpty else { return [:] }

        var dict: [String: [Int: [Int]]] = [:]
        for s in withTrigger {
            let trigger = s.triggerA!
            let hour = Calendar.current.component(.hour, from: s.timestamp)
            let guilt = s.guiltLevelC!
            dict[trigger, default: [:]][hour, default: []].append(guilt)
        }

        return dict.mapValues { hourMap in
            hourMap.map { hour, guilts -> HeatmapCell in
                let avg = Double(guilts.reduce(0, +)) / Double(guilts.count)
                return HeatmapCell(hour: hour, avgGuilt: avg)
            }
            .sorted { $0.hour < $1.hour }
        }
    }

    private var bubbleData: [BubbleItem] {
        let withTrigger = filteredSessions.filter { $0.triggerA != nil }
        guard !withTrigger.isEmpty else { return [] }

        let grouped = Dictionary(grouping: withTrigger) { $0.triggerA! }
        return grouped.map { trigger, items -> BubbleItem in
            let avgMin = items.map { $0.duration / 60 }.reduce(0, +) / Double(items.count)
            let guilts = items.compactMap { $0.guiltLevelC }.map(Double.init)
            let avgGuilt = guilts.isEmpty ? 0 : guilts.reduce(0, +) / Double(guilts.count)
            return BubbleItem(trigger: trigger, avgMinutes: avgMin, avgGuilt: avgGuilt, openCount: items.count)
        }
    }

    private var autoInsights: [String] {
        var results: [String] = []

        // Find highest guilt trigger + time
        let withBoth = filteredSessions.filter { $0.triggerA != nil && $0.guiltLevelC != nil }
        if withBoth.count >= 5 {
            let grouped = Dictionary(grouping: withBoth) { s -> String in
                let hour = Calendar.current.component(.hour, from: s.timestamp)
                let timeLabel = hour < 6 ? "深夜" : hour < 12 ? "午前" : hour < 18 ? "午後" : "夜間"
                return "\(timeLabel)の「\(s.triggerA!)」"
            }
            if let worst = grouped.max(by: { a, b in
                let avgA = a.value.compactMap(\.guiltLevelC).map(Double.init).reduce(0, +) / Double(a.value.count)
                let avgB = b.value.compactMap(\.guiltLevelC).map(Double.init).reduce(0, +) / Double(b.value.count)
                return avgA < avgB
            }) {
                let avg = worst.value.compactMap(\.guiltLevelC).map(Double.init).reduce(0, +) / Double(worst.value.count)
                if avg > 5 {
                    results.append("\(worst.key)でセッション終了した際の罪悪感が平均\(String(format: "%.1f", avg))と高い傾向があります。")
                }
            }
        }

        // Most frequent trigger
        let triggerGroups = Dictionary(grouping: filteredSessions.filter { $0.triggerA != nil }) { $0.triggerA! }
        if let topTrigger = triggerGroups.max(by: { $0.value.count < $1.value.count }),
           topTrigger.value.count >= 3 {
            results.append("「\(topTrigger.key)」がきっかけになっているセッションが最も多く、\(topTrigger.value.count)回記録されています。")
        }

        // Timeout ratio
        let timeouts = filteredSessions.filter { $0.endReason == .timeout }.count
        let total = filteredSessions.count
        if total > 0 {
            let ratio = Int(Double(timeouts) / Double(total) * 100)
            if ratio > 30 {
                results.append("セッションの\(ratio)%がタイムアウトで終了しています。セッション時間の短縮を検討してみましょう。")
            }
        }

        return results
    }
}

// MARK: - Chart Card

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            content()
        }
        .padding(16)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Heatmap Chart

struct HeatmapCell: Identifiable {
    let id = UUID()
    let hour: Int
    let avgGuilt: Double
}

struct HeatmapChart: View {
    let data: [String: [HeatmapCell]]

    private let hourLabels = stride(from: 0, to: 24, by: 3).map { "\($0)時" }
    private let hours = Array(stride(from: 0, to: 24, by: 1))

    var body: some View {
        VStack(spacing: 4) {
            // Header row
            HStack(spacing: 2) {
                Text("").frame(width: 80)
                ForEach(Array(stride(from: 0, to: 24, by: 3)), id: \.self) { h in
                    Text("\(h)")
                        .font(.system(size: 8, weight: .light))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(data.keys.sorted(), id: \.self) { trigger in
                HStack(spacing: 2) {
                    Text(trigger)
                        .font(.system(size: 10, weight: .light))
                        .lineLimit(1)
                        .frame(width: 80, alignment: .trailing)
                        .padding(.trailing, 4)

                    ForEach(hours, id: \.self) { hour in
                        let cell = data[trigger]?.first { $0.hour == hour }
                        let intensity = cell.map { $0.avgGuilt / 10 } ?? 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(intensity > 0
                                  ? Color(red: intensity, green: 0.2, blue: 0.5 - intensity * 0.3)
                                  : Color.primary.opacity(0.04))
                            .frame(height: 24)
                    }
                }
            }
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.indigo.opacity(0.4))
                .frame(width: 2)
                .clipShape(Capsule())
            Text(text)
                .font(.system(size: 13, weight: .light))
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
