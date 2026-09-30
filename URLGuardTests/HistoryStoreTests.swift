import XCTest
@testable import URLGuard

@MainActor
final class HistoryStoreTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var fileURL: URL { directory.appendingPathComponent("history.json") }

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        suiteName = "URLGuardTests." + UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() async throws {
        try FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testHistoryOffByDefaultAndPersistsWhenEnabled() throws {
        let scan = try URLAnalyzer().analyze("https://example.com/")
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        XCTAssertFalse(store.isEnabled)
        store.save(scan)
        XCTAssertTrue(store.scans.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        store.setEnabled(true)
        store.save(scan)
        XCTAssertNil(store.storageError)
        XCTAssertEqual(store.scans, [scan])
        let restored = HistoryStore(fileURL: fileURL, defaults: defaults)
        XCTAssertTrue(restored.isEnabled)
        XCTAssertEqual(restored.scans, [scan])
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    func testDisableDeleteAndClear() throws {
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        store.setEnabled(true)
        let first = try URLAnalyzer().analyze("https://example.com/a")
        let second = try URLAnalyzer().analyze("https://example.com/b")
        store.save(first); store.save(second)
        store.setEnabled(false)
        store.save(try URLAnalyzer().analyze("https://example.com/c"))
        XCTAssertEqual(store.scans.count, 2)
        store.delete(first)
        XCTAssertEqual(store.scans, [second])
        store.clear()
        XCTAssertTrue(store.scans.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testHistoryLimit() throws {
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        store.setEnabled(true)
        for index in 0...100 { store.save(try URLAnalyzer().analyze("https://example.com/\(index)")) }
        XCTAssertNil(store.storageError)
        XCTAssertEqual(store.scans.count, 100)
        XCTAssertEqual(store.scans.first?.normalizedURL, "https://example.com/100")
        XCTAssertEqual(store.scans.last?.normalizedURL, "https://example.com/1")
    }

    func testCorruptHistoryDoesNotCrashOrGetOverwritten() throws {
        try Data("not JSON".utf8).write(to: fileURL)
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        XCTAssertNotNil(store.storageError)
        store.setEnabled(true)
        store.save(try URLAnalyzer().analyze("https://example.com/"))
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "not JSON")
        store.clear()
        store.save(try URLAnalyzer().analyze("https://example.com/"))
        XCTAssertNil(store.storageError)
        XCTAssertEqual(store.scans.count, 1)
    }

    func testWriteFailureKeepsScanHistoryConsistent() throws {
        let blocked = directory.appendingPathComponent("blocked")
        try Data("file".utf8).write(to: blocked)
        let store = HistoryStore(fileURL: blocked.appendingPathComponent("history.json"), defaults: defaults)
        store.setEnabled(true)
        store.save(try URLAnalyzer().analyze("https://example.com/"))
        XCTAssertNotNil(store.storageError)
        XCTAssertTrue(store.scans.isEmpty)
    }
}
