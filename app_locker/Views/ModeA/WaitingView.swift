import SwiftUI

struct WaitingView: View {
    @ObservedObject var viewModel: ModeAViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 60) {
                Spacer()

                headerSection
                countdownSection
                footerSection

                Spacer()

                cancelButton
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("今日 \(viewModel.dailyLaunchCount) 回目")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .tracking(1)
            Text("少し待ってください")
                .font(.system(size: 20, weight: .light))
        }
    }

    private var countdownSection: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 6)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: viewModel.waitProgressFraction)
                .stroke(Color.primary.opacity(0.5), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.waitProgressFraction)

            VStack(spacing: 4) {
                Text(viewModel.waitTimeFormatted)
                    .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                Text("秒")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("衝動の波は60〜90秒でおさまります")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var cancelButton: some View {
        Button {
            viewModel.cancelWait()
        } label: {
            Text("やっぱりやめる")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(.secondary)
        }
    }
}
