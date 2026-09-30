import SwiftUI

extension RiskLevel {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    var symbol: String {
        switch self {
        case .low: return "checkmark.shield"
        case .medium, .high: return "exclamationmark.triangle"
        }
    }
}

struct GuardCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct PlainURLText: View {
    let value: String
    var body: some View {
        // Text, rather than Link or Markdown, keeps scanned URLs non-interactive.
        Text(verbatim: value)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SafetyAdvice: View {
    private let suggestions = [
        "Verify the domain carefully.",
        "Do not enter passwords or payment information unless you trust the website.",
        "Instead of following an unexpected link, open the organisation’s official app or website yourself.",
        "If unsure, do not open the link."
    ]
    var body: some View {
        GuardCard {
            Label("What should I do?", systemImage: "shield").font(.headline)
            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                    Text(suggestion)
                }
            }
        }
    }
}
