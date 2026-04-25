import SwiftUI
import SwiftData

struct DiaryEntryView: View {
    @Bindable var session: SessionRecord
    let onComplete: () -> Void

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<CustomOption> { $0.categoryRaw == "A" },
           sort: \CustomOption.usageCount, order: .reverse)
    private var triggersA: [CustomOption]

    @Query(filter: #Predicate<CustomOption> { $0.categoryRaw == "B" },
           sort: \CustomOption.usageCount, order: .reverse)
    private var beliefsB: [CustomOption]

    @Query(filter: #Predicate<CustomOption> { $0.categoryRaw == "D" },
           sort: \CustomOption.usageCount, order: .reverse)
    private var disputesD: [CustomOption]

    @State private var guiltLevel: Double = 5
    @State private var planE = ""
    @State private var showingCustomA = false
    @State private var showingCustomD = false

    private let defaultTriggers = ["暇つぶし", "現実逃避", "情報収集", "連絡確認", "仕事・勉強", "習慣（無意識）"]
    private let defaultBeliefs = ["つい開いてしまった", "一瞬だけと思った", "これくらいはいい", "不安を紛らわしたかった"]
    private let defaultDisputes = ["代わりに本を読む", "散歩に出る", "深呼吸を3回する", "水を飲む", "ノートに書く"]

    private var isTimeout: Bool { session.endReason == .timeout }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    if isTimeout {
                        timeoutHeader
                    }

                    stepA
                    stepB
                    stepC
                    stepD
                    stepE

                    saveButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("ABCDE 日記")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("後で") { onComplete() }
                }
            }
        }
        .sheet(isPresented: $showingCustomA) {
            CustomInputSheet(placeholder: "きっかけを入力") { text in
                let opt = CustomOption(category: .triggerA, content: text)
                context.insert(opt)
                session.triggerA = text
            }
        }
        .sheet(isPresented: $showingCustomD) {
            CustomInputSheet(placeholder: "反論を入力") { text in
                let opt = CustomOption(category: .disputeD, content: text)
                context.insert(opt)
                session.disputeD = text
            }
        }
    }

    // MARK: - Sections

    private var timeoutHeader: some View {
        VStack(spacing: 4) {
            Text("セッション終了")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(1)
            Text("今の気分は？")
                .font(.system(size: 22, weight: .light))
        }
    }

    private var stepA: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "A — きっかけ", title: "開こうとした理由")

            FlowLayout(spacing: 8) {
                ForEach(defaultTriggers + triggersA.map(\.content), id: \.self) { t in
                    TagChip(label: t, isSelected: session.triggerA == t) {
                        session.triggerA = t
                    }
                }
                TagChip(label: "+ カスタム", isSelected: false) {
                    showingCustomA = true
                }
            }
        }
    }

    private var stepB: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "B — 自動思考", title: "使っている間、どんな考えが浮かんだ？")

            FlowLayout(spacing: 8) {
                ForEach(defaultBeliefs + beliefsB.map(\.content), id: \.self) { b in
                    TagChip(label: b, isSelected: session.beliefB == b) {
                        session.beliefB = b
                    }
                }
            }
        }
    }

    private var stepC: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "C — 感情", title: "罪悪感スコア")

            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Slider(value: $guiltLevel, in: 1...10, step: 1)
                    .tint(guiltColor)
                    .onChange(of: guiltLevel) { _, v in session.guiltLevelC = Int(v) }
                Text("10")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("\(Int(guiltLevel))")
                .font(.system(size: 40, weight: .ultraLight, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(guiltColor)
        }
    }

    private var stepD: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "D — 反論", title: "次回同じ状況になったら？")

            FlowLayout(spacing: 8) {
                ForEach(defaultDisputes + disputesD.map(\.content), id: \.self) { d in
                    TagChip(label: d, isSelected: session.disputeD == d) {
                        session.disputeD = d
                    }
                }
                TagChip(label: "+ カスタム", isSelected: false) {
                    showingCustomD = true
                }
            }
        }
    }

    private var stepE: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "E — 行動計画", title: "明日、衝動を感じたら代わりにすることは？")

            TextEditor(text: $planE)
                .font(.system(size: 15, weight: .light))
                .frame(minHeight: 100)
                .padding(12)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: planE) { _, v in session.planE = v }
        }
    }

    private var saveButton: some View {
        Button {
            session.isCompleted = true
            try? context.save()
            onComplete()
        } label: {
            Text("記録する")
                .font(.system(size: 16, weight: .light))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundStyle(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var guiltColor: Color {
        let fraction = (guiltLevel - 1) / 9
        return Color(red: fraction, green: 0.3, blue: 1 - fraction)
    }
}
