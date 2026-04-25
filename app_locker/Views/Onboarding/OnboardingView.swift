import SwiftUI
import SwiftData
import FamilyControls

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel
    @Query private var settingsList: [AppSettings]

    @State private var page: Int = 0
    @State private var selectedMode: ModeType = .modeA
    @State private var selectedSessionMinutes: Int = 5
    @State private var isPickerPresented = false

    private var settings: AppSettings {
        if let s = settingsList.first { return s }
        let s = AppSettings()
        context.insert(s)
        return s
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch page {
            case 0: welcomePage
            case 1: modeSelectionPage
            case 2: sessionDurationPage
            case 3: appSelectionPage
            default: EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: page)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 48) {
            Spacer()

            VStack(spacing: 16) {
                Text("App Locker")
                    .font(.system(size: 36, weight: .light, design: .default))
                    .tracking(2)

                Text("ABCDE Edition")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .tracking(4)
            }

            VStack(spacing: 12) {
                Text("無意識の衝動を")
                Text("意識的な選択へ。")
            }
            .font(.system(size: 20, weight: .light))
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            Spacer()

            nextButton("はじめる")
        }
        .padding(40)
    }

    private var modeSelectionPage: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("モードを選んでください")
                    .font(.system(size: 22, weight: .light))
                Text("後から変更できます")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                ForEach(ModeType.allCases, id: \.self) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode)
                        .onTapGesture { selectedMode = mode }
                }
            }

            Spacer()

            nextButton("次へ")
        }
        .padding(.horizontal, 24)
    }

    private var sessionDurationPage: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("1セッションの時間")
                    .font(.system(size: 22, weight: .light))
                Text("自分で決めた時間が目標になります")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach([3, 5, 10, 15, 30], id: \.self) { minutes in
                    SessionDurationRow(minutes: minutes, isSelected: selectedSessionMinutes == minutes)
                        .onTapGesture { selectedSessionMinutes = minutes }
                }
            }

            Spacer()

            nextButton("次へ")
        }
        .padding(.horizontal, 24)
    }

    private var appSelectionPage: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("制限するアプリを選ぶ")
                    .font(.system(size: 22, weight: .light))
                Text("X、Instagram、TikTokなど依存しているアプリ")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("アプリを選択")
                }
                .font(.system(size: 16, weight: .light))
                .frame(maxWidth: .infinity)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
            }
            .foregroundStyle(.primary)
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $appVM.lockService.selection
            )
            .onChange(of: appVM.lockService.selection) { _, newVal in
                appVM.lockService.updateSelection(newVal)
            }

            Spacer()

            Button {
                finishOnboarding()
            } label: {
                Text("完了")
                    .font(.system(size: 16, weight: .light))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func finishOnboarding() {
        appVM.completeOnboarding(
            mode: selectedMode,
            sessionMinutes: selectedSessionMinutes,
            settings: settings,
            context: context
        )
        Task { await appVM.lockService.requestAuthorization() }
    }

    private func nextButton(_ label: String) -> some View {
        Button {
            page += 1
        } label: {
            Text(label)
                .font(.system(size: 16, weight: .light))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundStyle(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Subviews

private struct ModeCard: View {
    let mode: ModeType
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mode.displayName)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            Text(mode.description)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primary : Color.primary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

private struct SessionDurationRow: View {
    let minutes: Int
    let isSelected: Bool

    var body: some View {
        HStack {
            Text("\(minutes)分")
                .font(.system(size: 15, weight: .light))
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.primary : Color.primary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}
