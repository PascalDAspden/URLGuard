import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var history: HistoryStore
    @State private var confirmClear = false

    var body: some View {
        List {
            Section {
                Toggle("Save scans on this device", isOn: Binding(
                    get: { history.isEnabled }, set: { history.setEnabled($0) }
                ))
            } footer: {
                Text("Optional and off by default. Stores up to 100 scans. Turning it off stops new saves; use Clear all history to remove previous scans. URLs may contain private tokens.")
            }
            if let message = history.storageError {
                Section { Text(message).foregroundStyle(.orange) }
            }
            Section("Previous scans") {
                if history.scans.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("No saved scans", systemImage: "clock").font(.headline)
                        Text("Enable history, then check a URL to save it here.").foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                }
                ForEach(history.scans) { scan in
                    NavigationLink {
                        ResultView(result: scan)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbatim: scan.hostname).font(.headline).lineLimit(2)
                            Label("\(scan.riskLevel.rawValue) · \(scan.riskScore)/10", systemImage: scan.riskLevel.symbol)
                                .foregroundStyle(scan.riskLevel.color).font(.subheadline)
                            Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 4)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { history.delete(scan) }
                    }
                }
            }
            Section {
                Button("Clear all history", role: .destructive) { confirmClear = true }
                    .disabled(history.scans.isEmpty && history.storageError == nil)
            }
        }
        .navigationTitle("History")
        .confirmationDialog("Delete all saved scans?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Delete all history", role: .destructive) { history.clear() }
        } message: { Text("This cannot be undone.") }
    }
}
