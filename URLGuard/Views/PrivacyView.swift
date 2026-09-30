import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                Label("Analysis stays on your device", systemImage: "lock.shield").font(.headline)
                Text("URLGuard performs URL analysis locally on your device. Version 1 does not send URLs to an external server.")
                Text("No account, analytics, tracking, advertising, paid API, or AI service is used.")
            }
            Section("Clipboard") {
                Text("Clipboard text is pasted only when you use the system Paste button or the text field’s paste action. URLGuard does not monitor your clipboard.")
            }
            Section("Optional history") {
                Text("History is off by default. If enabled, URLGuard saves the URL, hostname, time, score and checks to an app-private file on this device. The history directory is excluded from device backup.")
                Text("URLs may include private tokens or personal information. Swipe to delete a scan or choose Clear all history. Turning history off does not delete existing scans.")
            }
            Section("What analysis does") {
                Text("URLGuard examines the URL text. It does not open the URL, load a website, resolve DNS, follow redirects, or check current threat intelligence.")
            }
            Section("Educational tool") {
                Text("A heuristic score is not a guarantee of safety or maliciousness. URLGuard is not a replacement for professional threat intelligence or browser security systems.")
            }
        }
        .navigationTitle("Privacy")
    }
}
