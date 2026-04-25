import SwiftUI
import SwiftData

struct ModeAHomeView: View {
    @StateObject private var viewModel = ModeAViewModel()
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch viewModel.phase {
                case .idle:
                    idleView
                case .waiting:
                    WaitingView(viewModel: viewModel)
                case .sessionActive:
                    SessionActiveView(viewModel: viewModel)
                case .sessionEnded:
                    sessionEndedView
                }
            }
            .navigationTitle("Heavy Lock")
            .navigationBarTitleDisplayMode(.large)
            .animation(.easeInOut(duration: 0.5), value: viewModel.phase)
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 48) {
            Spacer()

            VStack(spacing: 8) {
                Text("本日の起動回数")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                Text("\(viewModel.dailyLaunchCount)")
                    .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                Text(viewModel.waitTimeLabel)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("制限アプリを開こうとすると")
                Text("ここでシミュレーションできます")
            }
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)

            Button {
                viewModel.beginWaitPhase()
            } label: {
                Text("制限アプリを開く（テスト）")
                    .font(.system(size: 15, weight: .light))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Session Ended

    private var sessionEndedView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Text("セッション終了")
                    .font(.system(size: 24, weight: .light))
                Text("使用時間に到達しました")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }

            Text("今の気持ちを記録しましょう")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(.secondary)

            Button {
                let session = SessionRecord(appBundleID: "", endReason: .timeout)
                context.insert(session)
                appVM.pendingDiarySession = session
                appVM.showingDiaryEntry = true
                viewModel.phase = .idle
            } label: {
                Text("ABCDE日記を書く")
                    .font(.system(size: 16, weight: .light))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            Button {
                viewModel.phase = .idle
            } label: {
                Text("スキップ")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
