import Foundation
import Darwin

protocol URLAnalyzing {
    func analyze(_ input: String) throws -> ScanResult
}

enum URLAnalysisError: LocalizedError, Equatable {
    case invalidURL, inputTooLong

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Please enter a valid URL."
        case .inputTooLong: return "This URL is too long to analyse. Please use a URL under 32,768 characters."
        }
    }
}

/// Pure string analysis: no URLSession, DNS, redirects, WebView, or website loading.
struct URLAnalyzer: URLAnalyzing {
    func analyze(_ input: String) throws -> ScanResult {
        guard input.count <= URLRules.maximumInputLength else { throw URLAnalysisError.inputTooLong }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              !trimmed.contains("\\"), validPercentEscapes(trimmed) else {
            throw URLAnalysisError.invalidURL
        }

        var candidate = trimmed
        var notes: [String] = []
        if trimmed != input { notes.append("Whitespace around the URL was removed.") }
        if candidate.hasPrefix("//") {
            candidate = "https:" + candidate
            notes.append("No scheme was supplied. HTTPS was assumed; it was not verified.")
        } else if !candidate.contains("://") {
            // Accept host:port input, but reject mailto:, javascript:, file:, and other schemes.
            let firstPart = String(candidate.prefix { $0 != "/" && $0 != "?" && $0 != "#" })
            if firstPart.contains(":"), !firstPart.hasPrefix("[") {
                let pieces = firstPart.split(separator: ":", omittingEmptySubsequences: false)
                guard pieces.count == 2, !pieces[1].isEmpty,
                      pieces[1].allSatisfy({ $0.isASCII && $0.isNumber }) else {
                    throw URLAnalysisError.invalidURL
                }
            }
            candidate = "https://" + candidate
            notes.append("No scheme was supplied. HTTPS was assumed; it was not verified.")
        }

        guard var components = URLComponents(string: candidate),
              let rawScheme = components.scheme,
              ["http", "https"].contains(rawScheme.lowercased()),
              let parsedURL = components.url,
              let parsedHost = parsedURL.host, !parsedHost.isEmpty else {
            throw URLAnalysisError.invalidURL
        }
        let scheme = rawScheme.lowercased()
        let host = parsedHost.lowercased()
        let hostWithoutBrackets = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let hostname = hostWithoutBrackets.hasSuffix(".") ? String(hostWithoutBrackets.dropLast()) : hostWithoutBrackets
        let isIP = isIPAddress(hostname)
        guard isIP || validDomain(hostname) else { throw URLAnalysisError.invalidURL }
        if let port = components.port, !(1...65535).contains(port) { throw URLAnalysisError.invalidURL }
        // An empty :port is not silently treated as a valid explicit port.
        guard let schemeEnd = candidate.range(of: "://")?.upperBound else { throw URLAnalysisError.invalidURL }
        let authority = candidate[schemeEnd...].prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        guard !authority.hasSuffix(":"), !authority.contains(where: { $0.isWhitespace }) else {
            throw URLAnalysisError.invalidURL
        }
        components.scheme = scheme
        guard let normalizedURL = components.url?.absoluteString else { throw URLAnalysisError.invalidURL }
        if normalizedURL != candidate {
            notes.append("The system URL parser normalised the URL, including any spaces or international characters.")
        }

        var signals: [DetectedSignal] = []
        var passed: [PassedCheck] = []
        func check(_ condition: Bool, id: String, title: String, detail: String,
                   severity: SignalSeverity = .minor, passedTitle: String, passedDetail: String) {
            if condition {
                signals.append(DetectedSignal(id: id, title: title, description: detail,
                    severity: severity, scoreContribution: URLRules.weight(id)))
            } else {
                passed.append(PassedCheck(id: id, title: passedTitle, description: passedDetail))
            }
        }

        check(scheme == "http", id: "http", title: "HTTP is used",
              detail: "The scheme does not request HTTPS encryption. Avoid entering sensitive information.",
              passedTitle: "HTTPS is specified",
              passedDetail: "The URL requests HTTPS. No connection or certificate was checked; HTTPS does not prove trustworthiness.")
        check(isIP, id: "ipAddress", title: "IP address destination",
              detail: "The URL uses an IP address instead of a normal domain. Local devices and legitimate services can also use IP addresses.",
              severity: .strong, passedTitle: "Uses a domain name", passedDetail: "The hostname is not a standard IPv4 or IPv6 address.")
        let labels = hostname.split(separator: ".")
        // Count labels rather than guessing the registered domain. No public suffix database is used.
        check(!isIP && labels.count >= URLRules.manyHostnameLabels, id: "subdomains", title: "Several subdomains detected",
              detail: "The hostname contains \(labels.count) labels. Several subdomains can make the real destination harder to identify. This is a label-count heuristic, not a registered-domain lookup.",
              passedTitle: "No unusually deep hostname", passedDetail: "Fewer than \(URLRules.manyHostnameLabels) hostname labels, or an IP address.")
        let decoded = candidate.removingPercentEncoding ?? candidate
        let tokens = Set(decoded.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        let matches = URLRules.keywords.intersection(tokens).sorted()
        check(!matches.isEmpty, id: "keywords", title: "Sensitive-action words found",
              detail: "Contains: \(matches.joined(separator: ", ")). These words also appear in legitimate URLs and contribute only one point in total.",
              passedTitle: "No listed keywords detected", passedDetail: "No whole-word matches for the local keyword list.")
        let shortener = URLRules.shorteners.contains { hostname == $0 || hostname.hasSuffix("." + $0) }
        check(shortener, id: "shortener", title: "Known URL shortening service",
              detail: "Shortened URLs can hide the final destination. URLGuard does not expand links or contact the service.",
              severity: .moderate, passedTitle: "No listed shortener detected", passedDetail: "The hostname did not match the bundled shortener list; other services may exist.")
        check(candidate.contains("@"), id: "atSign", title: "@ character detected",
              detail: "Unusual URL formatting can make the true destination confusing. In the authority, text before @ is user information, not the destination. In paths or queries, @ may be ordinary data.",
              severity: .moderate, passedTitle: "No @ character", passedDetail: "No literal @ character appears in this URL.")
        check(candidate.count > URLRules.longURLLength, id: "longURL", title: "Very long URL",
              detail: "This URL has \(candidate.count) characters. Long links can be harder to inspect, but many legitimate links are long.",
              passedTitle: "URL length within threshold", passedDetail: "At most \(URLRules.longURLLength) characters.")
        check(hostname.filter { $0 == "-" }.count >= URLRules.manyHyphens, id: "hyphens", title: "Multiple hostname hyphens",
              detail: "The hostname contains at least \(URLRules.manyHyphens) hyphens. This may make brand-like names confusing, but hyphens alone do not indicate phishing.",
              passedTitle: "No excessive hostname hyphens", passedDetail: "Fewer than \(URLRules.manyHyphens) hyphens in the hostname.")
        let nonstandardPort = components.port.map { $0 != (scheme == "https" ? 443 : 80) } ?? false
        check(nonstandardPort, id: "port", title: "Non-standard port",
              detail: "The URL explicitly uses port \(components.port ?? 0). Development servers and legitimate services also use non-standard ports.",
              passedTitle: "Default port or no explicit port", passedDetail: "No port mismatch with the usual port for this scheme.")
        check(labels.contains { $0.hasPrefix("xn--") }, id: "punycode", title: "Punycode domain",
              detail: "This domain uses Punycode. Punycode can legitimately represent international domain names, but it can also be used to create visually misleading domains.",
              severity: .moderate, passedTitle: "No Punycode labels detected", passedDetail: "No hostname label begins with xn--.")
        let escapeCount = candidate.filter { $0 == "%" }.count
        check(escapeCount >= URLRules.manyPercentEscapes, id: "encoding", title: "Extensive percent encoding",
              detail: "There are \(escapeCount) percent-encoded sequences. Encoding is normal in URLs, but extensive encoding can make text harder to inspect.",
              passedTitle: "No excessive percent encoding", passedDetail: "Fewer than \(URLRules.manyPercentEscapes) percent-encoded sequences.")
        let query = components.percentEncodedQuery ?? ""
        let parameterCount = query.split(separator: "&", omittingEmptySubsequences: true).count
        check(parameterCount > URLRules.manyQueryParameters || query.count > URLRules.largeQueryLength,
              id: "parameters", title: "Large query string",
              detail: "The query contains \(parameterCount) parameters and \(query.count) encoded characters. Tracking, search and sign-in links can legitimately have large queries.",
              passedTitle: "Query within thresholds", passedDetail: "At most \(URLRules.manyQueryParameters) parameters and \(URLRules.largeQueryLength) encoded query characters.")
        let unusual = trimmed.contains(where: { $0.isWhitespace }) || decoded.unicodeScalars.contains {
            CharacterSet.controlCharacters.contains($0) || (0x202A...0x202E).contains($0.value) || (0x2066...0x2069).contains($0.value)
        }
        check(unusual, id: "unusualFormatting", title: "Unusual formatting",
              detail: "Spaces, encoded control characters or direction-changing characters can obscure a URL. Review the displayed hostname carefully.",
              passedTitle: "No listed formatting anomalies", passedDetail: "No spaces or listed control/direction characters detected.")
        let score = min(URLRules.maximumScore, signals.reduce(0) { $0 + $1.scoreContribution })
        return ScanResult(id: UUID(), date: Date(), originalURL: input, normalizedURL: normalizedURL,
                          hostname: hostname, scheme: scheme, riskScore: score,
                          riskLevel: RiskLevel(score: score), detectedSignals: signals,
                          passedChecks: passed, normalizationNotes: notes)
    }

    private func isIPAddress(_ host: String) -> Bool {
        var ipv4 = in_addr()
        var ipv6 = in6_addr()
        return host.withCString { inet_pton(AF_INET, $0, &ipv4) == 1 || inet_pton(AF_INET6, $0, &ipv6) == 1 }
    }

    private func validDomain(_ host: String) -> Bool {
        // Foundation's URL host uses IDNA/Punycode for international names.
        guard host.utf8.count <= 253, !host.contains(":"),
              !host.allSatisfy({ $0.isNumber || $0 == "." }) else { return false }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2 else { return false } // Reject "hello" and bare local names.
        return labels.allSatisfy { label in
            !label.isEmpty && label.utf8.count <= 63 && label.first != "-" && label.last != "-" &&
            label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        } && (labels.last?.contains(where: { $0.isLetter }) ?? false)
    }

    private func validPercentEscapes(_ string: String) -> Bool {
        let bytes = Array(string.utf8)
        var index = 0
        func isHex(_ byte: UInt8) -> Bool {
            (48...57).contains(byte) || (65...70).contains(byte) || (97...102).contains(byte)
        }
        while index < bytes.count {
            if bytes[index] == 37 {
                guard index + 2 < bytes.count, isHex(bytes[index + 1]), isHex(bytes[index + 2]) else { return false }
                index += 3
            } else { index += 1 }
        }
        return true
    }
}
