import Foundation
import os

/// JSON-file persistence for dictation history at
/// `~/Library/Application Support/Blabber/history.json`. Records are kept
/// newest-first. Failures are logged and swallowed — a corrupt or missing
/// file yields an empty history rather than blocking the app.
struct HistoryStore {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "history")
    let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Blabber", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("history.json")
    }

    func load() -> [TranscriptionRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try Self.decoder.decode([TranscriptionRecord].self, from: data)
        } catch {
            log.error("Failed to decode history: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func save(_ records: [TranscriptionRecord]) {
        do {
            let data = try Self.encoder.encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            log.error("Failed to save history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
