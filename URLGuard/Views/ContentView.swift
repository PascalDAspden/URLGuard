import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Check", systemImage: "shield") }
            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock") }
            NavigationStack { LearnView() }
                .tabItem { Label("Learn", systemImage: "info.circle") }
            NavigationStack { PrivacyView() }
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .tint(.accentColor)
    }
}
