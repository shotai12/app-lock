import SwiftUI
import SwiftData

struct ReflectionView: View {
    @ObservedObject var viewModel: ModeBViewModel
    @Environment(\.modelContext) private var context

    @State private var selectedBelief: String?
    @State private var guiltLevel: Double = 5
    @State private var selectedDispute: String?
    @State private var showingDisputeInput = false
    @State private var customDispute = ""

    private var elapsedText: String {
        "\(viewModel.elapsedMinutes)分間使いました"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                header
                elapsedSection
                beliefSection
                guiltSection
                disputeSection

                actionButtons
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .sheet(isPresented: $showingDisputeInput) {
            CustomInputSheet(placeholder: "反論を入力") { text in
                selectedDispute = text
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("使用後の振り返り")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(1)
            Text("B・C・D")
                .font(.system(size: 22, weight: .light))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var elapsedSection: some View {
        HStack {
            Text(elapsedText)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var beliefSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "B", title: "使っている間、どんな気持ちでしたか？")

            FlowLayout(spacing: 8) {
                ForEach(viewModel.defaultBeliefs, id: \.self) { belief in
                    TagChip(label: belief, isSelected: selectedBelief == belief) {
                        selectedBelief = belief
                    }
                }
            }
        }
    }

    private var guiltSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "C", title: "罪悪感はどのくらい？")

            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Slider(value: $guiltLevel, in: 1...10, step: 1)
                    .tint(guiltColor)
                Text("10")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("\(Int(guiltLevel))")
                .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(guiltColor)
        }
    }

    private var disputeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(step: "D", title: "次回同じ状況になったらどうしますか？")

            FlowLayout(spacing: 8) {
                ForEach(viewModel.defaultDisputes, id: \.self) { dispute in
                    TagChip(label: dispute, isSelected: selectedDispute == dispute) {
                        selectedDispute = dispute
                    }
                }
                TagChip(label: "+ カスタム", isSelected: false) {
                    showingDisputeInput = true
                }
            }

            if let d = selectedDispute {
                Text("「\(d)」")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.recordReflection(
                    belief: selectedBelief,
                    guiltLevel: Int(guiltLevel),
                    dispute: selectedDispute,
                    context: context
                )
            } label: {
                Text("記録する")
                    .font(.system(size: 16, weight: .light))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                viewModel.skipReflection(context: context)
            } label: {
                Text("スキップ")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var guiltColor: Color {
        let fraction = (guiltLevel - 1) / 9
        return Color(
            red: fraction,
            green: 0.3,
            blue: 1 - fraction
        )
    }
}

// MARK: - Shared UI Helpers

struct SectionLabel: View {
    let step: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(step)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(2)
            Text(title)
                .font(.system(size: 15, weight: .light))
        }
    }
}

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: .light))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primary : Color.primary.opacity(0.05))
                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width + (rowWidth > 0 ? spacing : 0) > maxWidth {
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct CustomInputSheet: View {
    let placeholder: String
    let onConfirm: (String) -> Void

    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .light))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("カスタム追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        guard !text.isEmpty else { return }
                        onConfirm(text)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
