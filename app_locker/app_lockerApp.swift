import SwiftUI
import SwiftData
import FamilyControls

@main
struct AppLockerApp: App {
    @StateObject private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appVM)
        }
        .modelContainer(for: [
            SessionRecord.self,
            CustomOption.self,
            DailyLog.self,
            DailyAppStat.self,
            AppSettings.self,
        ])
    }
}

/// Thin wrapper that owns the model context and wires up app-level concerns.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appVM: AppViewModel
    @Query private var settingsList: [AppSettings]

    var body: some View {
        ContentView()
            .onOpenURL { url in
                appVM.handleDeepLink(url, context: context)
            }
            .task {
                await appVM.lockService.requestAuthorization()
                await NotificationService.shared.requestPermission()
                appVM.bootstrap(settings: settingsList.first)
            }
    }
}
