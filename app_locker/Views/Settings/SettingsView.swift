import SwiftUI
import SwiftData
import FamilyControls

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel
    @Query private var settingsList: [AppSettings]

    @State private var isPickerPresented = false
    @State private var showingModeConfirmation = false
    @State private var pendingMode: ModeType?
    @State private var selectedSessionMinutes: Int = 5
    @State private var showingSessionChangeAlert = false

    private var settings: AppSettings? { settingsList.first }

    private let sessionOptions = [3, 5, 10, 15, 30]

    var body: some View {
        NavigationStack {
            List {
                modeSection
                sessionSection
                appSelectionSection
                nightNotificationSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.insetGrouped)
        }
        .onAppear {
            selectedSessionMinutes = settings?.sessionDurationMinutes ?? 5
        }
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $appVM.lockService.selection
        )
        .onChange(of: appVM.lockService.selection) { _, newVal in
            appVM.lockService.updateSelection(newVal)
        }
        .alert("モード変更", isPresented: $showingModeConfirmation) {
            Button("変更する", role: .destructive) {
                if let mode = pendingMode, let s = settings {
                    appVM.switchMode(to: mode, settings: s, context: context)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("モードを変更しますか？")
        }
        .alert("セッション時間の変更", isPresented: $showingSessionChangeAlert) {
            Button("変更する") {
                applySessionChange()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("変更は翌日から適用されます。")
        }
    }

    // MARK: - Sections

    private var modeSection: some View {
        Section {
            ForEach(ModeType.allCases, id: \.self) { mode in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mode.displayName)
                            .font(.system(size: 15))
                        Text(mode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if appVM.currentMode == mode {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if appVM.currentMode != mode {
                        pendingMode = mode
                        showingModeConfirmation = true
                    }
                }
            }
        } header: {
            Text("モード")
        }
    }

    private var sessionSection: some View {
        Section {
            ForEach(sessionOptions, id: \.self) { minutes in
                HStack {
                    Text("\(minutes)分")
                        .font(.system(size: 15))
                    Spacer()
                    if selectedSessionMinutes == minutes {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedSessionMinutes != minutes {
                        selectedSessionMinutes = minutes
                        showingSessionChangeAlert = true
                    }
                }
            }
        } header: {
            Text("1セッション時間")
        } footer: {
            Text("変更は翌日から適用されます。")
                .font(.caption)
        }
    }

    private var appSelectionSection: some View {
        Section {
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Text("制限アプリを変更")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("制限対象アプリ")
        }
    }

    private var nightNotificationSection: some View {
        Section {
            if let s = settings {
                DatePicker(
                    "通知時刻",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                from: DateComponents(hour: s.nightNotificationHour, minute: s.nightNotificationMinute)
                            ) ?? Date()
                        },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            s.nightNotificationHour = comps.hour ?? 22
                            s.nightNotificationMinute = comps.minute ?? 0
                            try? context.save()
                            NotificationService.shared.scheduleEveningNotification(
                                hour: s.nightNotificationHour,
                                minute: s.nightNotificationMinute
                            )
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("夜の振り返り通知")
        }
    }

    // MARK: - Actions

    private func applySessionChange() {
        guard let s = settings else { return }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
        s.pendingSessionDurationMinutes = selectedSessionMinutes
        s.pendingSessionChangeDate = tomorrow
        try? context.save()
    }
}
