import SwiftUI

@main
struct LockinFocusApp: App {
    @StateObject private var deps = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deps)
        }
    }
}
