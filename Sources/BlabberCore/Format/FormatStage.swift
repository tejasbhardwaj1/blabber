import Foundation

/// Context a formatting stage can use to make app-aware decisions.
/// Minimal for now — grows in Phase 3 with the frontmost app's bundle
/// identifier for per-app tone profiles.
public struct FormatContext {
    public var frontmostBundleID: String?

    public init(frontmostBundleID: String? = nil) {
        self.frontmostBundleID = frontmostBundleID
    }
}

public protocol FormatStage {
    func apply(_ text: String, context: FormatContext) -> String
}
