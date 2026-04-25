import SwiftUI
import SwiftData

struct ModeBHomeView: View {
    @StateObject private var viewModel = ModeBViewModel()
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch viewModel.phase {
                case .idle:
                    idleView
                case .triggerRecording:
                    TriggerRecordView(viewModel: viewModel)
                case .sessionActive:
                    ModeBSessionView(viewModel: viewModel)
                case .reflectionRecording:
                    ReflectionView(viewModel: viewModel)
                case .done:
                    doneView
                }
            }
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.large)
            .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
        }
    }

    private var idleView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Text("スマホを開くときに")
                    .font(.system(size: 20, weight: .light))
                Text("きっかけを記録しましょう")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Text("記録の積み重ねで習慣が見えてきます")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.tertiary)

            Button {
                viewModel.startFlow(context: context)
            } label: {
                Text("スマホを開く")
                    .font(.system(size: 16, weight: .light))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var doneView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("記録完了")
                    .font(.system(size: 24, weight: .light))
                Text("お疲れさまでした")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.reset()
            } label: {
                Text("ホームに戻る")
                    .font(.system(size: 16, weight: .light))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}
