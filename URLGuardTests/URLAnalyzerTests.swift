import XCTest
@testable import URLGuard

final class URLAnalyzerTests: XCTestCase {
    private let analyzer = URLAnalyzer()

    private func signal(_ id: String, in input: String) throws -> DetectedSignal? {
        try analyzer.analyze(input).detectedSignals.first { $0.id == id }
    }

    func testNormalHTTPS() throws {
        let scan = try analyzer.analyze("https://www.example.com")
        XCTAssertEqual(scan.hostname, "www.example.com")
        XCTAssertEqual(scan.scheme, "https")
        XCTAssertEqual(scan.riskScore, 0)
        XCTAssertEqual(scan.riskLevel, .low)
        XCTAssertTrue(scan.detectedSignals.isEmpty)
        XCTAssertTrue(scan.passedChecks.contains { $0.id == "http" })
    }

    func testHTTPIsOnePoint() throws {
        let scan = try analyzer.analyze("http://www.example.com")
        XCTAssertEqual(scan.riskScore, 1)
        XCTAssertEqual(scan.riskLevel, .low)
    }

    func testIPExample() throws {
        let scan = try analyzer.analyze("http://192.0.2.1/login")
        XCTAssertEqual(scan.hostname, "192.0.2.1")
        XCTAssertEqual(scan.riskScore, 5)
        XCTAssertEqual(scan.riskLevel, .medium)
        XCTAssertEqual(try signal("ipAddress", in: scan.originalURL)?.scoreContribution, 3)
    }

    func testPrivateIPAndIPv6() throws {
        for url in ["http://192.168.1.50/login", "https://[2001:db8::1]/", "http://[::1]:8080/"] {
            XCTAssertNotNil(try signal("ipAddress", in: url), url)
            XCTAssertNil(try signal("subdomains", in: url), url)
        }
    }

    func testShortenersAndBoundary() throws {
        for host in ["bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "go.bit.ly"] {
            XCTAssertEqual(try signal("shortener", in: "https://\(host)/abc")?.scoreContribution, 2)
        }
        for host in ["notbit.ly", "bit.ly.example.com"] {
            XCTAssertNil(try signal("shortener", in: "https://\(host)/abc"))
        }
    }

    func testPunycodeAnyLabel() throws {
        XCTAssertNotNil(try signal("punycode", in: "https://xn--bcher-kva.example/"))
        XCTAssertNotNil(try signal("punycode", in: "https://www.xn--bcher-kva.example/"))
    }

    func testInternationalHostnameNormalization() throws {
        let scan = try analyzer.analyze("https://bücher.example/")
        XCTAssertEqual(scan.hostname, "xn--bcher-kva.example")
        XCTAssertNotNil(scan.detectedSignals.first { $0.id == "punycode" })
    }

    func testManySubdomains() throws {
        let scan = try analyzer.analyze("https://paypal.login.security.verify.example.com/account")
        XCTAssertEqual(scan.hostname, "paypal.login.security.verify.example.com")
        XCTAssertEqual(scan.riskScore, 2) // One keyword point, one depth point.
        XCTAssertNotNil(try signal("subdomains", in: scan.originalURL))
        XCTAssertNil(try signal("subdomains", in: "https://www.example.co.nz/"))
    }

    func testLongURLThreshold() throws {
        let base = "https://example.com/"
        XCTAssertNil(try signal("longURL", in: base + String(repeating: "a", count: 200 - base.count)))
        XCTAssertNotNil(try signal("longURL", in: base + String(repeating: "a", count: 201 - base.count)))
    }

    func testHyphensAndKeywordsAreWeak() throws {
        let scan = try analyzer.analyze("https://account-login-verification.example.xyz/verify")
        XCTAssertEqual(scan.riskScore, 1) // Two hyphens, below the three-hyphen threshold.
        XCTAssertEqual(scan.riskLevel, .low)
        XCTAssertNotNil(try signal("hyphens", in: "https://secure-paypal-login-account-verification.example.com/"))
        XCTAssertNil(try signal("hyphens", in: "https://example.com/a-b-c-d-e"))
    }

    func testAllKeywordsContributeOnlyOnePoint() throws {
        let scan = try analyzer.analyze("https://example.com/login/verify/verification/secure/update/account/banking/wallet/password/payment/invoice/authentication/confirm")
        XCTAssertEqual(scan.riskScore, 1)
        XCTAssertEqual(scan.riskLevel, .low)
        XCTAssertNil(try signal("keywords", in: "https://example.com/accountant/securely"))
        XCTAssertNotNil(try signal("keywords", in: "https://example.com/%6cogin"))
    }

    func testUnusualAndStandardPorts() throws {
        for port in [8080, 8443, 3000] {
            XCTAssertEqual(try signal("port", in: "https://example.com:\(port)/")?.scoreContribution, 1)
        }
        XCTAssertNil(try signal("port", in: "https://example.com:443/"))
        XCTAssertNil(try signal("port", in: "http://example.com:80/"))
        XCTAssertNotNil(try signal("port", in: "https://example.com:80/"))
    }

    func testAtSignTrueDestination() throws {
        let scan = try analyzer.analyze("https://paypal.example@destination.example.com/account")
        XCTAssertEqual(scan.hostname, "destination.example.com")
        XCTAssertEqual(scan.detectedSignals.first { $0.id == "atSign" }?.scoreContribution, 2)
        XCTAssertEqual(scan.riskScore, 3)
        XCTAssertNotNil(try signal("atSign", in: "https://example.com/?email=a@b.example"))
    }

    func testEncodingThresholdAndMalformedEscapes() throws {
        XCTAssertNil(try signal("encoding", in: "https://example.com/%41%42%43%44"))
        XCTAssertNotNil(try signal("encoding", in: "https://example.com/%41%42%43%44%45"))
        for url in ["https://example.com/%", "https://example.com/%GG", "https://example.com/%2"] {
            XCTAssertThrowsError(try analyzer.analyze(url))
        }
    }

    func testParameterAndQueryThresholds() throws {
        let eight = (1...8).map { "p\($0)=x" }.joined(separator: "&")
        XCTAssertNil(try signal("parameters", in: "https://example.com/?" + eight))
        XCTAssertNotNil(try signal("parameters", in: "https://example.com/?" + eight + "&p9=x"))
        XCTAssertNotNil(try signal("parameters", in: "https://example.com/?x=" + String(repeating: "a", count: 301)))
        XCTAssertNil(try signal("parameters", in: "https://example.com/#a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&i=9"))
    }

    func testUnusualFormatting() throws {
        XCTAssertNotNil(try signal("unusualFormatting", in: "https://example.com/a b"))
        XCTAssertNotNil(try signal("unusualFormatting", in: "https://example.com/%0A"))
        XCTAssertThrowsError(try analyzer.analyze("https://example.com/a\nb"))
        XCTAssertThrowsError(try analyzer.analyze("https://example.com\\fake"))
    }

    func testNormalizationAndSchemeCase() throws {
        let scan = try analyzer.analyze("  example.com  ")
        XCTAssertEqual(scan.originalURL, "  example.com  ")
        XCTAssertEqual(scan.normalizedURL, "https://example.com")
        XCTAssertFalse(scan.normalizationNotes.isEmpty)
        XCTAssertEqual(try analyzer.analyze("HTTPS://EXAMPLE.COM/").hostname, "example.com")
        XCTAssertEqual(try analyzer.analyze("example.com:8080/path").scheme, "https")
        XCTAssertEqual(try analyzer.analyze("//example.com/path").scheme, "https")
        XCTAssertEqual(try analyzer.analyze("https://example.com./").hostname, "example.com")
    }

    func testInvalidInputs() {
        for input in ["hello", "", "   ", "https://", "https://-bad.example/", "https://bad..example/",
                      "https://example.com:70000/", "https://example.com:0/", "https://example.com:/",
                      "https://example.com:abc/", "javascript:alert(1)", "file:///tmp/a", "ftp://example.com/",
                      "https://999.999.999.999/", "https://exa mple.com/", "mailto:a@example.com"] {
            XCTAssertThrowsError(try analyzer.analyze(input), input)
        }
    }

    func testInputLimit() {
        XCTAssertThrowsError(try analyzer.analyze(String(repeating: "a", count: URLRules.maximumInputLength + 1))) { error in
            XCTAssertEqual(error as? URLAnalysisError, .inputTooLong)
        }
    }

    func testScoreCapAndClassificationBoundaries() throws {
        let url = "http://a.b.c.xn--bcher-kva.example:8080/login-verify-account-update?a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&i=%41%42%43%44%45&email=a@b.example&padding=" + String(repeating: "a", count: 310)
        let scan = try analyzer.analyze(url)
        XCTAssertGreaterThan(scan.rawScore, 10)
        XCTAssertEqual(scan.riskScore, 10)
        XCTAssertEqual(scan.riskLevel, .high)
        for (score, level) in [(0, RiskLevel.low), (2, .low), (3, .medium), (5, .medium), (6, .high), (10, .high)] {
            XCTAssertEqual(RiskLevel(score: score), level)
        }
    }

    func testSameInputGivesSameAnalysis() throws {
        let a = try analyzer.analyze("http://192.0.2.1/login")
        let b = try analyzer.analyze("http://192.0.2.1/login")
        XCTAssertEqual(a.detectedSignals, b.detectedSignals)
        XCTAssertEqual(a.passedChecks, b.passedChecks)
        XCTAssertEqual(a.riskScore, b.riskScore)
    }
}
