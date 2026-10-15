import SwiftUI

/// Design tokens for Blabber. The app is built to look and behave like a
/// native macOS 26 app (Voice Memos / System Settings), so it leans on
/// system semantics rather than a bespoke palette — Light/Dark, Increase
/// Contrast, Dynamic Type and the user's chosen accent color all work
/// automatically:
///
/// - **Type**: standard SF text styles (`.body`, `.headline`, `.caption`,
///   …) are used directly in views. Those *are* the tokens — they're
///   system-defined, not one-off sizes. The only alias here is a role
///   that needs a modifier (the monospaced-digit timer).
/// - **Color**: system semantic colors (`.primary`, `.secondary`, window
///   and material backgrounds) are used directly in views. The one named
///   color below is `recordIndicator` (systemRed), used nowhere but the
///   record dot.
/// - **Accent**: the system accent color, which shows because nothing
///   overrides `.tint`.
///
/// Spacing (a 4/8 grid), corner radius (standard macOS radii) and motion
/// are the only numeric tokens. Every view pulls spacing, radius, the
/// record color, and animation from here — no one-off values in
/// components.
enum DesignTokens {

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 6   // controls, chips
        static let medium: CGFloat = 10  // cards, grouped containers
        static let large: CGFloat = 14   // large panels
    }

    enum Color {
        /// The single non-semantic color in the app: the recording
        /// indicator dot. systemRed, and nothing else uses it.
        static let recordIndicator = SwiftUI.Color(nsColor: .systemRed)
    }

    enum Typography {
        /// Elapsed-time readout — a standard title style with monospaced
        /// digits so the width doesn't jitter as the seconds tick.
        static let timer = Font.system(.title, design: .default).monospacedDigit()
    }

    enum Motion {
        /// UI transitions stay well under 300ms, ease-out, and touch only
        /// transform/opacity. `standard(reduceMotion:)` returns nil under
        /// Reduce Motion, so callers hand nil to `withAnimation`/
        /// `.animation` and the change applies instantly.
        ///
        /// Keyboard-initiated changes (recording started by the hotkey,
        /// the level meter, the record dot) are never wrapped in an
        /// animation at all — they appear instantly regardless of this.
        static let duration: Double = 0.2

        static func standard(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeOut(duration: duration)
        }
    }
}
