import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var history: HistoryStore
    @State private var input = ""
    @State private var result: ScanResult?
    @State private var showingResult = false
    @State private var errorMessage: String?
    @FocusState private var isEditing: Bool
    private let analyzer = URLAnalyzer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 42)).foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("URLGuard").font(.largeTitle.bold())
                    Text("Check a link before you open it.")
                        .font(.title3).foregroundStyle(.secondary)
                }
                .padding(.top, 14)
                GuardCard {
                    Text("URL to check").font(.headline)
                    TextField("https://www.example.com", text: $input, axis: .vertical)
                        .lineLimit(2...5)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isEditing)
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("URL to check")
                        .onChange(of: input) { _ in errorMessage = nil }
                    HStack {
                        // The system paste control reads clipboard contents only on user interaction.
                        PasteButton(payloadType: String.self) { strings in
                            if let first = strings.first { input = first; errorMessage = nil }
                        }
                        .buttonBorderShape(.capsule)
                        Spacer()
                        Button {
                            input = ""; errorMessage = nil
                        } label: { Label("Clear", systemImage: "xmark.circle") }
                        .disabled(input.isEmpty)
                    }
                    Text("A domain such as example.com will be checked as https://example.com. No connection is made.")
                        .font(.caption).foregroundStyle(.secondary)
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                    Button(action: checkURL) {
                        Label("Check URL", systemImage: "shield")
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                GuardCard {
                    Label("Local. Private. Explainable.", systemImage: "lock.shield").font(.headline)
                    Text("URLGuard checks the text of your link. It does not open websites, follow redirects, or check live threat databases.")
                        .foregroundStyle(.secondary)
                    Text("A low score is not a guarantee of safety.").font(.callout.bold())
                }
                Text(history.isEnabled ? "Local history is on. You can turn it off in History." : "History is off. Turn it on in History if you want to save scans.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Check a link")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingResult) {
            if let result { ResultView(result: result) }
        }
    }

    private func checkURL() {
        isEditing = false
        do {
            let scan = try analyzer.analyze(input)
            history.save(scan)
            result = scan
            showingResult = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
