import SwiftUI

struct SessionActiveView: View {
    @ObservedObject var viewModel: ModeAViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 60) {
                Spacer()

                VStack(spacing: 8) {
                    Text("使用中")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.secondary)
                        .tracking(2)
                    Text("残り時間")
                        .font(.system(size: 20, weight: .light))
                }

                sessionTimerRing

                VStack(spacing: 8) {
                    Text("セッション終了後にリダイレクトされます")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button {
                    viewModel.endSessionManually()
                } label: {
                    Text("今すぐ終了")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
    }

    private var sessionTimerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 6)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: 1.0 - viewModel.sessionProgressFraction)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.sessionProgressFraction)

            Text(viewModel.sessionTimeFormatted)
                .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
        }
    }
}
