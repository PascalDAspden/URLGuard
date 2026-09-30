import Foundation
import Combine

/// Local JSON persistence. History is opt-in, limited to 100 scans and excluded from backup.
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var scans: [ScanResult] = []
    @Published private(set) var isEnabled: Bool
    @Published private(set) var storageError: String?
    private let fileURL: URL
    private let defaults: UserDefaults
    private var loadFailed = false
    static let enabledKey = "urlguard.history.enabled"

    init(fileURL: URL? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.bool(forKey: Self.enabledKey)
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("URLGuard", isDirectory: true).appendingPathComponent("history.json")
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            do {
                let data = try Data(contentsOf: self.fileURL)
                scans = Array(try JSONDecoder().decode([ScanResult].self, from: data).prefix(100))
            } catch {
                loadFailed = true
                storageError = "Saved history could not be read. Clear history to reset it before saving new scans."
            }
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: Self.enabledKey)
    }

    func save(_ result: ScanResult) {
        guard isEnabled, !loadFailed else { return }
        commit(Array(([result] + scans.filter { $0.id != result.id }).prefix(100)))
    }

    func delete(_ result: ScanResult) {
        guard !loadFailed else { return }
        commit(scans.filter { $0.id != result.id })
    }

    func clear() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            scans = []
            storageError = nil
            loadFailed = false
        } catch {
            storageError = "History could not be deleted. Please try again."
        }
    }

    private func commit(_ updated: [ScanResult]) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var localDirectory = directory
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try localDirectory.setResourceValues(values)
            let data = try JSONEncoder().encode(updated)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            scans = updated
            storageError = nil
        } catch {
            storageError = "History could not be saved. Your scan result is still available on screen."
        }
    }
}
