import SwiftUI

struct LearnView: View {
    private let lessons: [(String, String)] = [
        ("What is a domain?", "A domain is a named address such as example.com. A hostname can include extra labels, such as login.example.com. Familiar brand words anywhere in a URL do not prove who operates it."),
        ("What is HTTPS?", "HTTPS requests an encrypted connection to a website. URLGuard only checks the URL scheme; it does not connect or inspect certificates."),
        ("What is phishing?", "Phishing is an attempt to trick you into sharing sensitive information or taking an unsafe action by pretending to be someone you trust."),
        ("Why can shortened links be risky?", "A short link hides the final destination until it redirects. Shorteners are often legitimate, but make an unexpected link harder to inspect."),
        ("What are subdomains?", "Subdomains are extra labels before a domain. In paypal.login.verify.example.com, the paypal label does not make it a PayPal website. Domain endings can include multiple labels, such as co.nz."),
        ("What is Punycode?", "Punycode represents international domain names using ASCII labels that begin with xn--. It is legitimate technology, but lookalike characters can also mislead readers."),
        ("Why doesn’t HTTPS guarantee trust?", "A fraudulent website can also use HTTPS. Encryption protects the connection; it does not verify an organisation’s honesty or the link’s purpose."),
        ("What does the score mean?", "Each matching rule adds its listed points once. The total is capped at 10: 0–2 Low, 3–5 Medium, and 6–10 High. These are heuristic categories, not measured probabilities. Ordinary URLs can trigger warnings; harmful links can trigger none.")
    ]
    var body: some View {
        List {
            Section("Link basics") {
                ForEach(lessons, id: \.0) { lesson in
                    DisclosureGroup(lesson.0) {
                        Text(lesson.1).padding(.vertical, 8)
                    }
                }
            }
            Section("Scoring rules") {
                ForEach(URLRules.weights.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(ruleTitle(key))
                        Spacer()
                        Text("+\(URLRules.weight(key))").monospacedDigit().foregroundStyle(.secondary)
                    }
                }
                Text("Rules and thresholds are documented in README.md and URLRules.swift.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Learn")
    }

    private func ruleTitle(_ key: String) -> String {
        ["http": "HTTP", "ipAddress": "IP address", "shortener": "Known shortener",
         "punycode": "Punycode", "subdomains": "5+ hostname labels",
         "longURL": "More than 200 characters", "hyphens": "3+ hostname hyphens",
         "keywords": "Listed words (maximum)", "port": "Non-standard port",
         "encoding": "5+ percent escapes", "parameters": "Large query string",
         "atSign": "@ character", "unusualFormatting": "Unusual formatting"][key] ?? key
    }
}
