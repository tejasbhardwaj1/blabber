import Foundation

/// Deterministic cleanup that always runs, independent of whether
/// Apple Intelligence / FoundationModels is available. Phase 1 ships
/// only filler-stripping and whitespace/sentence-casing cleanup, since
/// that's enough to prove the Formatter seam end-to-end; the dictionary,
/// snippets, and self-correction collapse land in Phase 3.
public struct RulesFormatter: FormatStage {
    private static let fillerPattern = try! NSRegularExpression(
        pattern: #"\b(um+|uh+|erm+)\b[,]?\s*"#,
        options: [.caseInsensitive]
    )

    public init() {}

    public func apply(_ text: String, context: FormatContext) -> String {
        var result = text

        let range = NSRange(result.startIndex..<result.endIndex, in: result)
        result = Self.fillerPattern.stringByReplacingMatches(in: result, range: range, withTemplate: "")

        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }

        return result
    }
}
