import SwiftUI

struct ModeBSessionView: View {
    @ObservedObject var viewModel: ModeBViewModel

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            VStack(spacing: 8) {
                Text("使用中")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.secondary)
                    .tracking(2)
                if let trigger = viewModel.currentSession?.triggerA {
                    Text(trigger)
                        .font(.system(size: 18, weight: .light))
                }
            }

            sessionRing

            Text("セッション終了後に振り返りを記録します")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                viewModel.endSessionManually()
            } label: {
                Text("スマホを閉じる")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 40)
    }

    private var sessionRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 6)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: 1.0 - viewModel.sessionProgressFraction)
                .stroke(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.5), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.sessionProgressFraction)

            Text(viewModel.sessionTimeFormatted)
                .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
        }
    }
}
