import SwiftUI

@main
struct SecretKitExtensions_DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(selection: .secureEnclave)
        }
    }
}
