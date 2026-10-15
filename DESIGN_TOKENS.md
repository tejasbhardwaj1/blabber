# Blabber design tokens

Source of truth is `Sources/Blabber/Design/DesignTokens.swift`. Blabber is
built to look and behave like a native macOS 26 app — Voice Memos and System
Settings are the references — so it leans on system semantics instead of a
custom design language. That is a deliberate choice: Light/Dark, Increase
Contrast, Dynamic Type, and the user's chosen accent color all work for free,
and the app reads as part of the system rather than a theme.

## What the system provides (used directly in views)

These are not re-declared as custom tokens because the system already defines
them. Using them directly *is* pulling from the token set, and avoids one-off
values:

- **Text** — standard SF text styles: `.largeTitle`, `.title`, `.headline`,
  `.body`, `.callout`, `.caption`. Views call `.font(.body)` etc. directly.
- **Color** — semantic colors: `.primary`, `.secondary`, `.tint`
  (= system accent), and system backgrounds/materials
  (`.regularMaterial`, grouped backgrounds, `Color(nsColor:)` window colors).
- **Accent** — the user's system accent color drives every control and
  selection. The app sets no `.tint` override, so whatever the user picked in
  System Settings → Appearance shows through.

## Named tokens (declared in `DesignTokens.swift`)

### Color

| Token | Value | Used for |
| --- | --- | --- |
| `Color.recordIndicator` | `systemRed` | The recording dot — the only use of red in the app. Controls, buttons, and selection all use the system accent, never red. |

### Typography

| Token | Value | Used for |
| --- | --- | --- |
| `Typography.timer` | `.title`, monospaced digits | The elapsed-time readout, so its width doesn't jitter as seconds tick |

All other text uses standard SF text styles directly.

### Spacing — 4 / 8 grid

| Token | Value |
| --- | --- |
| `Spacing.xs` | 4 |
| `Spacing.sm` | 8 |
| `Spacing.md` | 12 |
| `Spacing.lg` | 16 |
| `Spacing.xl` | 24 |
| `Spacing.xxl` | 32 |

### Corner radius — standard macOS radii

| Token | Value | Used for |
| --- | --- | --- |
| `Radius.small` | 6 | Controls, chips |
| `Radius.medium` | 10 | Cards, grouped containers |
| `Radius.large` | 14 | Large panels |

### Motion

| Token | Value | Rule |
| --- | --- | --- |
| `Motion.duration` | 0.2s | Under 300ms |
| `Motion.standard(reduceMotion:)` | ease-out @ `duration`, or `nil` | The standard UI transition; returns `nil` under Reduce Motion so the change is instant |

Motion rules, carried over unchanged:

- **No animation on keyboard-initiated actions.** Recording started by the
  hotkey, the live level meter, and the record dot all appear instantly —
  never wrapped in `withAnimation`.
- UI animation stays under 300ms, ease-out.
- Only `transform` and `opacity` animate. The level meter is **not** animated
  with a layout tween; it redraws directly from the real mic level each audio
  tick (like a real meter / Voice Memos), which keeps it to data-driven motion
  with no height-animation.
- Reduce Motion is respected everywhere via `Motion.standard(reduceMotion:)`
  (AppKit source: `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`,
  SwiftUI: `@Environment(\.accessibilityReduceMotion)`).

## Removed in the native redirect

The earlier tape-recorder direction is gone entirely: silkscreen labels and
Helvetica Neue, panel seams, recessed bays, pressed-button faces, the
graphite/cream palette, the VU-needle geometry and ballistics, the status/
correction/pill/selection color tokens, and the neutral accent override. Where
those encoded behavior worth keeping (a record color, a timer face, the motion
rules), it's re-expressed above in system terms.
