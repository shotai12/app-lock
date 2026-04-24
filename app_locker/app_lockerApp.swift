import SwiftUI
import FamilyControls // これを追加！

@main
struct AppLockerPrototypeApp: App {
    // 権限を管理するセンター
    let center = AuthorizationCenter.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // アプリ起動時に権限を要求する
                    Task {
                        do {
                            try await center.requestAuthorization(for: .individual)
                            print("承認されました！")
                        } catch {
                            print("承認エラー: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
}

