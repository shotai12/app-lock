import SwiftUI
import SwiftData

struct TriggerRecordView: View {
    @ObservedObject var viewModel: ModeBViewModel
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<CustomOption> { $0.categoryRaw == "A" },
           sort: \CustomOption.usageCount, order: .reverse)
    private var customTriggers: [CustomOption]

    @State private var showingCustomInput = false
    @State private var newTrigger = ""

    private var allTriggers: [String] {
        viewModel.defaultTriggers + customTriggers.map(\.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(allTriggers, id: \.self) { trigger in
                        TriggerRow(label: trigger) {
                            recordTrigger(trigger)
                        }
                    }

                    addCustomRow
                }
                .padding(.horizontal, 24)
            }

            skipButton
                .padding(24)
        }
        .sheet(isPresented: $showingCustomInput) {
            CustomInputSheet(placeholder: "きっかけを入力") { text in
                addCustomTrigger(text)
                recordTrigger(text)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A — きっかけ")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(1)
            Text("今スマホを開く理由は？")
                .font(.system(size: 22, weight: .light))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addCustomRow: some View {
        Button {
            showingCustomInput = true
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 13))
                Text("カスタム追加")
                    .font(.system(size: 15, weight: .light))
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 16)
        }
    }

    private var skipButton: some View {
        Button {
            viewModel.skipTrigger()
        } label: {
            Text("スキップ")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.secondary)
        }
    }

    private func recordTrigger(_ trigger: String) {
        viewModel.recordTrigger(trigger, context: context)
    }

    private func addCustomTrigger(_ text: String) {
        let option = CustomOption(category: .triggerA, content: text)
        context.insert(option)
        try? context.save()
    }
}

struct TriggerRow: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)
        }
        Divider().opacity(0.4)
    }
}
