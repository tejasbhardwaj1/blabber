import AppKit
import SwiftUI

/// Design tokens for Blabber's interface shell.
///
/// Every view pulls color, type, spacing, radius, border, shadow, and
/// motion values from here — no one-off constants in components. This
/// is the only place that encodes the 1980s field-recorder material
/// language (brushed aluminum, matte plastic, silkscreen labels); it
/// applies only to specific surfaces (transport controls, VU meter,
/// counter, panel seams), not to standard macOS chrome, which stays on
/// system defaults so the window still reads as a Mac app.
///
/// See DESIGN_TOKENS.md for the plain-language version with swatches.
enum DesignTokens {

    // MARK: - Color

    enum Color {
        // Surfaces
        static let bgCanvas = dynamic(light: 0xEDE8DE, dark: 0x1C1C1D)
        static let bgPanel = dynamic(light: 0xDEDAD0, dark: 0x2A2A2C)
        static let bgPanelRecessed = dynamic(light: 0xCFCAC0, dark: 0x141415)
        static let bgControl = dynamic(light: 0xE7E3D9, dark: 0x333335)
        static let bgControlPressed = dynamic(light: 0xDAD5C9, dark: 0x3D3D40)

        // Text
        static let textPrimary = dynamic(light: 0x262523, dark: 0xECE9E2)
        /// Darkened from the original #6E6B66 to clear 4.5:1 on its common
        /// hosts. Fails on `bgPanelRecessed` (light, 4.27:1) and on
        /// `bgControl`/`bgControlPressed` (dark, 4.48/3.85:1) — see the
        /// contrast table in DESIGN_TOKENS.md. By rule, `textSecondary` is
        /// not used on those four surfaces; they carry `textPrimary` or
        /// `textSilkscreen` only.
        static let textSecondary = dynamic(light: 0x5C5953, dark: 0x9C9A95)
        static let textSilkscreen = dynamic(light: 0x4B4844, dark: 0xB7B4AC)

        // Seams & borders — a seam is a 1pt highlight line directly above
        // a 1pt shadow line (2pt total), not a single stroke.
        static let borderHairline = dynamic(light: 0x000000, lightAlpha: 0.12, dark: 0xFFFFFF, darkAlpha: 0.08)
        static let seamHighlight = dynamic(light: 0xFFFFFF, lightAlpha: 0.65, dark: 0xFFFFFF, darkAlpha: 0.06)
        static let seamShadow = dynamic(light: 0x000000, lightAlpha: 0.18, dark: 0x000000, darkAlpha: 0.55)

        // Accent — one only, the record light. Everything else is
        // neutral. Amber/green are reserved for level/meter readout.
        // Rule: `accentRecord` never colors small text — only the record
        // dot, icons, and large type (e.g. an active counter digit).
        // Contrast against canvas/panel (3.5–4.2:1) is sufficient for
        // those non-text/large-text uses but not for body-sized text.
        static let accentRecord = dynamic(light: 0xC8392B, dark: 0xE0483A)
        static let meterAmber = dynamic(light: 0xD9A52C, dark: 0xE6B33C)
        static let meterGreen = dynamic(light: 0x4C8C4A, dark: 0x5FA25C)

        /// Neutral graphite/silver accent for selection, focus rings, and
        /// the app's `AccentColor` — set so system controls, text
        /// selection, and highlight never default to blue, and never
        /// read as "recording" red. Red stays reserved for the record
        /// state. Meets 3:1 (non-text component contrast) against canvas
        /// and panel in both appearances.
        static let accentNeutral = dynamic(light: 0x766F60, dark: 0xACA9A0)

        /// A translucent wash, not a solid fill — sits over whatever
        /// text color is already in place, so it doesn't need its own
        /// contrast check against text.
        static let textSelectionBackground = dynamic(light: 0x766F60, lightAlpha: 0.18, dark: 0xACA9A0, darkAlpha: 0.22)
        static let textSelectionForeground = textPrimary

        // Status — neutral tone; severity is carried by icon + weight
        // (e.g. exclamationmark.triangle / xmark.octagon), never by hue,
        // so these never compete with the one record-red accent.
        static let statusWarning = textSilkscreen
        static let statusError = textPrimary

        // Correction tag (history rows): a quiet chip, not a colored
        // badge — corrections are shown, not alarmed about.
        static let correctionTagBackground = bgControl
        static let correctionTagBorder = borderHairline
        static let correctionTagText = textSilkscreen

        // Pill (Phase E listening indicator): always renders in its own
        // fixed dark material, independent of system appearance — it's
        // a HUD overlay, not a window. Values below are intentionally
        // not run through `dynamic(light:dark:)`.
        static let pillSurfaceBackground = SwiftUI.Color(nsColor: NSColor(hex: 0x1C1C1D, alpha: 0.92))
        static let pillSurfaceText = SwiftUI.Color(nsColor: NSColor(hex: 0xECE9E2, alpha: 1))
        static let pillSurfaceAccent = SwiftUI.Color(nsColor: NSColor(hex: 0xE0483A, alpha: 1))

        /// Builds a SwiftUI `Color` that tracks system appearance, going
        /// through `NSColor(name:dynamicProvider:)` rather than an asset
        /// catalog — this package has no .xcassets pipeline, and a
        /// per-target SwiftPM resource bundle would be more machinery
        /// than six dynamic colors need.
        static func dynamic(light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) -> SwiftUI.Color {
            let nsColor = NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return isDark
                    ? NSColor(hex: dark, alpha: darkAlpha)
                    : NSColor(hex: light, alpha: lightAlpha)
            }
            return SwiftUI.Color(nsColor: nsColor)
        }
    }

    // MARK: - Type scale

    /// Body text, controls, and navigation stay on system fonts (San
    /// Francisco) at system sizes — that's what keeps the window reading
    /// as a native Mac app. Only the two "instrument" roles below depart
    /// from it, and only on the specific surfaces named in each case.
    enum Typography {
        /// Small uppercase labels silkscreened onto a panel: transport
        /// button captions, meter scale labels, section tags on the
        /// Dictionary/History panels. Always paired with `.textSilkscreen`
        /// and `.tracking(silkscreenTracking)`, and always uppercased by
        /// the call site — the token doesn't transform text itself.
        static let silkscreenLabel = Font.custom("Helvetica Neue", size: 10).weight(.medium)
        static let silkscreenTracking: Double = 1.4

        /// Tabular/monospaced numerals for the counter and timecode:
        /// recording duration, history timestamps' HH:MM, dictionary
        /// entry counts. Uses the system monospaced face, not a bundled
        /// font.
        static let counterNumeral = Font.system(size: 15, weight: .medium, design: .monospaced)
        static let counterNumeralLarge = Font.system(size: 28, weight: .medium, design: .monospaced)

        // Standard system roles, named here only so views reference the
        // token instead of ad hoc `.system(size:)` calls.
        static let title = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 15, weight: .semibold)
        static let body = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48

        /// Gap between transport buttons (start/stop/etc.) — tighter than
        /// `md` so the row reads as one control cluster, not a list.
        static let controlGutter: CGFloat = 10
    }

    // MARK: - Corner radius

    /// Deliberately squared, not pill-shaped — buttons look pressed, not
    /// tinted. Nothing in this app should round past `panel`.
    enum Radius {
        static let panel: CGFloat = 10      // window sections, cards
        static let control: CGFloat = 6     // buttons, text fields
        static let recessed: CGFloat = 4    // meter well, counter window
        static let none: CGFloat = 0        // hairline dividers
    }

    // MARK: - Border

    enum Border {
        static let hairline: CGFloat = 1       // standard seam/divider
        /// Each line of a bevel pair. A seam is `seamHighlight` drawn 1pt
        /// above `seamShadow` — 2pt total (`seamTotal`), never a single
        /// stroke.
        static let seam: CGFloat = 1
        static let seamTotal: CGFloat = seam * 2
        static let focusRing: CGFloat = 2      // keyboard focus indicator
    }

    // MARK: - State

    enum States {
        /// Applied to disabled controls (opacity only — no desaturation
        /// pass, since the palette is already neutral).
        static let disabledOpacity: Double = 0.35
    }

    // MARK: - VU meter geometry

    /// Needle position and zone geometry for the level meter. Ballistics
    /// (how the needle *moves*) live in `Motion`, not here.
    enum VUMeter {
        /// Total sweep of the needle from rest to full scale.
        static let arcSweepDegrees: Double = 80
        /// Needle angle at rest (0 level), measured from vertical.
        static let arcRestDegrees: Double = -40
        /// Fraction of the scale (0...1) where the green zone ends and
        /// amber begins. No red zone on the meter face — the one red in
        /// this app is the record light, not a clip warning.
        static let greenZoneEnd: Double = 0.75
        /// Fraction of the scale where the amber zone ends (top of scale).
        static let amberZoneEnd: Double = 1.0
        static let majorTickCount: Int = 5
        static let minorTicksPerMajor: Int = 3
    }

    // MARK: - Shadow

    struct Shadow {
        let color: SwiftUI.Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    enum Shadows {
        /// A panel lifted slightly off the canvas — soft, ambient.
        static let panelElevation = Shadow(color: SwiftUI.Color.black.opacity(0.14), radius: 8, x: 0, y: 2)
        /// Resting button — subtle grounding, not a floating-card shadow.
        static let buttonRest = Shadow(color: SwiftUI.Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
        /// SwiftUI has no cheap true inset shadow; the pressed look is
        /// built from `bgControlPressed` plus this overlay darkening the
        /// upper edge, simulating light falling into a recess.
        static let pressedOverlayOpacity: Double = 0.12
    }

    // MARK: - Motion

    enum Motion {
        /// Anything triggered by the hotkey or another keyboard action —
        /// the pill, meter arming, recording-state text — uses this: no
        /// animation, full stop. Keyboard actions are repeated hundreds
        /// of times a day; animating them makes the app feel laggy.
        static let instant: Double = 0

        static let buttonPress: Double = 120
        static let buttonRelease: Double = 160
        /// Standard UI enter/exit: list rows, popovers, the Settings
        /// sheet. Kept under 300ms per the motion brief.
        static let ui: Double = 220

        /// VU-style ballistic time constant for the level meter needle,
        /// in milliseconds. This is **not** passed to a SwiftUI
        /// `Animation` — the needle tracks a continuously-changing input
        /// (real mic level), not a single destination value, so it's
        /// implemented as per-frame exponential smoothing:
        /// `displayed += (target - displayed) * (1 - exp(-dt / (needleSmoothingTimeConstantMs / 1000)))`
        /// run once per audio/display tick. A timed easing animation
        /// would retarget-stutter every time the input changes mid-flight.
        static let needleSmoothingTimeConstantMs: Double = 300

        static let easeOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: ui / 1000)
        static let easeInOut = Animation.timingCurve(0.77, 0, 0.175, 1, duration: ui / 1000)

        static func easeOut(_ durationMs: Double) -> Animation {
            .timingCurve(0.23, 1, 0.32, 1, duration: durationMs / 1000)
        }
        static func easeInOut(_ durationMs: Double) -> Animation {
            .timingCurve(0.77, 0, 0.175, 1, duration: durationMs / 1000)
        }
    }
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: Double) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }
}
