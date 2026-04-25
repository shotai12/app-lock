import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appVM: AppViewModel

    @State private var selectedTab: Tab = .home

    enum Tab { case home, diary, reports, settings }

    var body: some View {
        Group {
            if !appVM.isOnboardingComplete {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .sheet(isPresented: $appVM.showingDiaryEntry) {
            if let session = appVM.pendingDiarySession {
                DiaryEntryView(session: session) {
                    appVM.showingDiaryEntry = false
                    appVM.pendingDiarySession = nil
                }
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tabItem { Label("ホーム", systemImage: "house") }
                .tag(Tab.home)

            DiaryListView()
                .tabItem { Label("日記", systemImage: "book") }
                .tag(Tab.diary)

            ReportView()
                .tabItem { Label("レポート", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.reports)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }

    @ViewBuilder
    private var homeView: some View {
        switch appVM.currentMode {
        case .modeA:
            ModeAHomeView()
        case .modeB:
            ModeBHomeView()
        }
    }
}
