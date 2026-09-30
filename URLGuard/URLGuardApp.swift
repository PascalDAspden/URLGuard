import SwiftUI

@main
@MainActor
struct URLGuardApp: App {
    @StateObject private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(history)
        }
    }
}
