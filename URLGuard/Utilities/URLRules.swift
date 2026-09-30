import Foundation

/// All policy choices are here. A rule contributes only once per scan.
/// This is a transparent heuristic, not a calibrated probability of phishing.
enum URLRules {
    static let maximumScore = 10
    static let maximumInputLength = 32_768 // Prevent enormous pasted inputs from blocking the UI.
    static let longURLLength = 200
    static let manyHostnameLabels = 5
    static let manyHyphens = 3
    static let manyPercentEscapes = 5
    static let manyQueryParameters = 8
    static let largeQueryLength = 300

    static let weights: [String: Int] = [
        "http": 1, "ipAddress": 3, "shortener": 2, "punycode": 2,
        "subdomains": 1, "longURL": 1, "hyphens": 1, "keywords": 1,
        "port": 1, "encoding": 1, "parameters": 1, "atSign": 2,
        "unusualFormatting": 1
    ]

    static let keywords: Set<String> = [
        "login", "verify", "verification", "secure", "update", "account",
        "banking", "wallet", "password", "payment", "invoice",
        "authentication", "confirm"
    ]
    // Exact hostname matches, plus subdomains of these services.
    // This offline list is intentionally small and can be edited without an API.
    static let shorteners: Set<String> = [
        "bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "ow.ly",
        "buff.ly", "rebrand.ly", "cutt.ly", "tiny.cc", "rb.gy"
    ]

    static func weight(_ rule: String) -> Int { weights[rule, default: 0] }
}
