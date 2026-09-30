import SwiftUI

struct ResultView: View {
    let result: ScanResult
    @EnvironmentObject private var history: HistoryStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GuardCard {
                    Label(result.riskLevel.rawValue, systemImage: result.riskLevel.symbol)
                        .font(.largeTitle.bold()).foregroundStyle(result.riskLevel.color)
                    Text("Risk score: \(result.riskScore) / \(URLRules.maximumScore)")
                        .font(.title2.bold())
                    Text(result.detectedSignals.isEmpty ? "No obvious suspicious characteristics detected." : result.riskLevel.summary)
                    Text("Heuristic score, not a probability or guarantee. This does not prove that a website is safe or malicious.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Checked \(result.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                GuardCard {
                    Label("Actual hostname", systemImage: "link").font(.headline)
                    PlainURLText(value: result.hostname).fontWeight(.semibold)
                    Text("This is the destination host parsed from the link. Read the whole hostname carefully: brand names in earlier labels do not identify the owner. This app does not look up the registered domain or its ownership.")
                        .font(.callout).foregroundStyle(.secondary)
                    Divider()
                    Text("Analysed URL").font(.subheadline.bold())
                    PlainURLText(value: result.normalizedURL)
                    if result.originalURL != result.normalizedURL {
                        Text("Original input").font(.subheadline.bold())
                        PlainURLText(value: result.originalURL)
                    }
                    ForEach(result.normalizationNotes, id: \.self) { note in
                        Text(note).font(.caption).foregroundStyle(.secondary)
                    }
                }
                GuardCard {
                    Text("Checks").font(.title2.bold())
                    if result.detectedSignals.isEmpty {
                        Text("No scoring signals detected.").foregroundStyle(.secondary)
                    }
                    ForEach(result.detectedSignals) { signal in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(signal.title).font(.headline)
                                Text(signal.description).font(.callout).foregroundStyle(.secondary)
                                Text("+\(signal.scoreContribution) · \(signal.severity.rawValue.capitalized) signal")
                                    .font(.caption.bold())
                            }
                        }.padding(.vertical, 4)
                    }
                    DisclosureGroup("Passed checks (\(result.passedChecks.count))") {
                        ForEach(result.passedChecks) { check in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle").foregroundStyle(.green).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(check.title).font(.subheadline.bold())
                                    Text(check.description).font(.caption).foregroundStyle(.secondary)
                                }
                            }.padding(.vertical, 5)
                        }
                    }
                    Text("Signal total: \(result.rawScore). The displayed score is capped at 10. Low: 0–2 · Medium: 3–5 · High: 6–10.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                SafetyAdvice()
                if let message = history.storageError {
                    Text(message).font(.caption).foregroundStyle(.orange)
                }
            }.padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("URLGuard")
        .navigationBarTitleDisplayMode(.inline)
    }
}
