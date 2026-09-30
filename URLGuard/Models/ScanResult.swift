import Foundation

enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case low = "Low Risk", medium = "Medium Risk", high = "High Risk"

    init(score: Int) {
        switch score {
        case 0...2: self = .low
        case 3...5: self = .medium
        default: self = .high
        }
    }

    var summary: String {
        switch self {
        case .low: return "No obvious suspicious characteristics detected, or only minor warnings found."
        case .medium: return "This URL contains characteristics worth checking carefully."
        case .high: return "This URL contains several characteristics commonly associated with suspicious links."
        }
    }
}

enum SignalSeverity: String, Codable, Sendable {
    case minor, moderate, strong
}

struct DetectedSignal: Identifiable, Codable, Equatable, Sendable {
    // Stable rule identifiers make testing and future rule additions straightforward.
    let id: String
    let title: String
    let description: String
    let severity: SignalSeverity
    let scoreContribution: Int
}

struct PassedCheck: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
}

struct ScanResult: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let originalURL: String
    let normalizedURL: String
    let hostname: String
    let scheme: String
    let riskScore: Int
    let riskLevel: RiskLevel
    let detectedSignals: [DetectedSignal]
    let passedChecks: [PassedCheck]
    let normalizationNotes: [String]

    var rawScore: Int { detectedSignals.reduce(0) { $0 + $1.scoreContribution } }
}
