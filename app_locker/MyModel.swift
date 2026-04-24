import SwiftUI // ←これを追加しました！
import FamilyControls
import ManagedSettings
import Combine

class MyModel: ObservableObject {
    static let shared = MyModel()

    // ユーザーが選んだアプリの情報を保存する変数
    @Published var selectionToDiscourage = FamilyActivitySelection() {
        didSet {
            // 選ばれたアプリが変わったら、すぐに制限をかけるメソッドを呼ぶ
            applyShields()
        }
    }

    // 選ばれたアプリにシールド（ロック）をかける設定
    let store = ManagedSettingsStore()

    func applyShields() {
        // 選ばれたアプリの「トークン（識別子）」を取り出して、シールドの対象にセットする
        store.shield.applications = selectionToDiscourage.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            selectionToDiscourage.categoryTokens
        )
    }
}
//
//  MyModel.swift
//  app_locker
//
//  Created by 吉岡晃基　 on 2026/04/24.
//

