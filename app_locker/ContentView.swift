import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject var model = MyModel.shared
    @State var isPickerPresented = false

    var body: some View {
        VStack(spacing: 20) {
            Text("App Locker プロトタイプ")
                .font(.title)

            Button("制限するアプリを選ぶ") {
                isPickerPresented = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        // ここがAppleが用意してくれている専用のピッカー！
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $model.selectionToDiscourage
        )
    }
}

