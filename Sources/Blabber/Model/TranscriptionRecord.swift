import Foundation

/// One saved dictation.
///
/// `text` is what the user ends up with (cleaned up by the formatter, and
/// later by the dictionary); `original` is the raw transcript before any
/// cleanup. `original` is stored now, while both are usually identical, so
/// that correction details ("what the dictionary changed") can be shown
/// later without a data migration.
struct TranscriptionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    var text: String
    var original: String

    init(id: UUID = UUID(), date: Date = Date(), text: String, original: String) {
        self.id = id
        self.date = date
        self.text = text
        self.original = original
    }
}
