# Blabber design tokens

Source of truth is `Sources/Blabber/Design/DesignTokens.swift`. This file explains
the same values in plain language. Every view pulls from the token file — no
one-off colors, spacing, or motion constants in components.

Scope: these tokens dress specific "instrument" surfaces — transport buttons, the
VU meter, the counter, panel seams. Everything else (window chrome, toolbar, list
rows, text fields, the Settings scene) stays on standard macOS system controls and
system fonts. The goal is a Mac app with tape-deck details, not a tape-deck skin
wearing a window.

## Direction

1980s portable tape recorder / field recorder — the sober, industrial side (Braun,
Nakamichi, Marantz), not the colorful consumer side. Brushed aluminum and matte
plastic surfaces, warm greys, off-black, cream, silver. One accent color: the red
of a record light. Amber and green are reserved for level/meter readout, never
used decoratively. No neon, vaporwave, gradients, glowing text, or chrome
lettering.

## Appearance: Light and Dark

The app follows system appearance automatically — no in-app override, per the
"native macOS behavior" requirement. Both palettes are real material choices, not
one inverted from the other:

- **Dark** is the primary/reference appearance. Instrument panels read most like
  the real object in a dim graphite/anodized-aluminum finish, the way a cassette
  deck's fascia looks under studio lighting — this is where the brief's reference
  gear (Nakamichi, Marantz) lives visually.
- **Light** is a genuine second material, not a filter: cream-and-silver ABS
  plastic and brushed aluminum under daylight, closer to Braun's lighter consumer
  gear. Panel, seam, and shadow values were picked independently for this mode,
  not derived by inverting dark-mode numbers.

## Color

| Token | Light | Dark | Used for |
| --- | --- | --- | --- |
| `bgCanvas` | `#EDE8DE` cream | `#1C1C1D` off-black | Window background |
| `bgPanel` | `#DEDAD0` warm silver | `#2A2A2C` graphite | Raised faceplate panels (history list, dictionary editor, meter housing) |
| `bgPanelRecessed` | `#CFCAC0` | `#141415` | Inset bays — the meter well, the counter window |
| `bgControl` | `#E7E3D9` | `#333335` | Button face at rest |
| `bgControlPressed` | `#DAD5C9` | `#3D3D40` | Button face while pressed |
| `textPrimary` | `#262523` | `#ECE9E2` | Body text, titles |
| `textSecondary` | `#5C5953` | `#9C9A95` | Metadata, timestamps, helper text — **not** used on `bgPanelRecessed`/`bgControl`/`bgControlPressed` (see contrast audit below) |
| `textSilkscreen` | `#4B4844` | `#B7B4AC` | Uppercase labels printed on a panel (transport captions, meter scale); also backs `statusWarning` and `correctionTagText` |
| `borderHairline` | black 12% | white 8% | Standard dividers |
| `seamHighlight` | white 65% | white 6% | Top edge of a bevel pair — the "lit" edge of a seam |
| `seamShadow` | black 18% | black 55% | Bottom edge of a bevel pair — the "shadowed" edge of a seam |
| `accentRecord` | `#C8392B` | `#E0483A` | The one accent: record dot, icons, large type (recording state) — **never small text**, see rule below |
| `meterAmber` | `#D9A52C` | `#E6B33C` | VU meter — approaching hot |
| `meterGreen` | `#4C8C4A` | `#5FA25C` | VU meter — normal level |
| `accentNeutral` | `#766F60` | `#ACA9A0` | App `AccentColor`, focus rings, selection tint — see rule below |
| `textSelectionBackground` | `accentNeutral` @ 18% | `accentNeutral` @ 22% | Text selection highlight (translucent wash over existing text) |
| `textSelectionForeground` | = `textPrimary` | = `textPrimary` | Text color while selected |
| `statusWarning` | = `textSilkscreen` (`#4B4844`) | = `textSilkscreen` (`#B7B4AC`) | Warning rows/badges — paired with an icon (e.g. `exclamationmark.triangle`), never amber |
| `statusError` | = `textPrimary` (`#262523`) | = `textPrimary` (`#ECE9E2`) | Error rows/badges — paired with an icon (e.g. `xmark.octagon`) and bolder weight, never red |
| `correctionTagBackground` | = `bgControl` | = `bgControl` | History-row "correction fired" chip |
| `correctionTagBorder` | = `borderHairline` | = `borderHairline` | Chip border |
| `correctionTagText` | = `textSilkscreen` | = `textSilkscreen` | Chip text |
| `pillSurfaceBackground` | `#1C1C1D` @ 92% (fixed) | same (fixed) | Phase E listening pill — always dark material, ignores system appearance |
| `pillSurfaceText` | `#ECE9E2` (fixed) | same (fixed) | Pill text/icon |
| `pillSurfaceAccent` | `#E0483A` (fixed) | same (fixed) | Pill's own accent (recording state) |

**Rule — accent discipline:** `accentRecord` colors only the record dot, icons, and
large type; it is never used for small/body text (its contrast against canvas/panel
is 3.5–4.2:1, enough for a large glyph but not for 13pt text). `accentNeutral`
is the app's `AccentColor` — selection, focus rings, and text highlight all use it,
so nothing in the app recruits system blue, and red stays exclusively meaningful as
"recording."

**Rule — status is neutral:** `statusWarning`/`statusError` carry severity through
an icon and type weight, not hue. Neither amber nor red is reused for status, so
those colors keep one meaning each (meter level, recording).

Seams (the visible line between two panels) are **two strokes, not one**:
`seamHighlight` drawn 1pt, directly above `seamShadow` drawn 1pt — 2pt total
(`Border.seamTotal`) — a cheap, convincing bevel without a real 3D render.

### Contrast audit (WCAG 2.1, text ≥4.5:1 / non-text UI ≥3:1)

Every text-color × background-color pair actually used, computed against the
values above:

| Pair | Light | Dark | Verdict |
| --- | --- | --- | --- |
| `textPrimary` on `bgCanvas` | 12.54 | 14.04 | Pass |
| `textPrimary` on `bgPanel` | 10.97 | 11.81 | Pass |
| `textPrimary` on `bgPanelRecessed` | 9.38 | 15.18 | Pass |
| `textPrimary` on `bgControl` | 11.95 | 10.40 | Pass |
| `textPrimary` on `bgControlPressed` | 10.46 | 8.93 | Pass |
| `textSecondary` on `bgCanvas` | 5.72 | 6.06 | Pass |
| `textSecondary` on `bgPanel` | 5.00 | 5.10 | Pass |
| `textSecondary` on `bgPanelRecessed` | **4.27** | 6.55 | **Fails in light** — see restriction below |
| `textSecondary` on `bgControl` | 5.45 | **4.48** | **Fails in dark** (just under threshold) |
| `textSecondary` on `bgControlPressed` | 4.77 | **3.85** | **Fails in dark** |
| `textSilkscreen` on all five backgrounds | 5.57–7.45 | 5.23–8.89 | Pass |
| `accentRecord` on `bgCanvas` | 4.22 | 4.18 | Pass as large text/icon only (≥3:1); not valid for small text |
| `accentRecord` on `bgPanel` | 3.69 | 3.52 | Pass as large text/icon only; not valid for small text |
| `accentNeutral` on `bgCanvas`/`bgPanel` (non-text, 3:1 target) | 4.08 / 3.57 | 7.25 / 6.10 | Pass |

**Resolution:** rather than chase one secondary-text color through every surface
(which would either wash it out on canvas or make it indistinguishable from
primary text), `textSecondary` is restricted by rule to surfaces it already clears:
`bgCanvas`, `bgPanel`, and `bgControlPressed`-in-light. It is never placed on
`bgPanelRecessed` (the meter well and counter window only ever show
`counterNumeral` text, colored `textPrimary`) or on `bgControl`/`bgControlPressed`
in dark mode (button captions use `textPrimary` or `textSilkscreen`, never
secondary/metadata-weight text). No button or recessed bay in this app needs
secondary text in practice, so the restriction costs nothing.

## Type scale

Body text, navigation, and controls stay on **San Francisco at system sizes** —
this is most of what keeps the window reading as a native Mac app. Only two roles
depart from it, and only on instrument surfaces:

| Role | Face | Size/weight | Where |
| --- | --- | --- | --- |
| Silkscreen label | Helvetica Neue, medium | 10pt, +1.4pt tracking, uppercase | Transport button captions, VU meter scale labels, small section tags |
| Counter numeral | System monospaced (SF Mono) | 15pt medium (28pt large variant) | Recording duration, history timestamps, dictionary entry counts |
| Title | System | 20pt semibold | Section/window titles |
| Headline | System | 15pt semibold | List row headers |
| Body | System | 13pt regular | Default text |
| Caption | System | 11pt regular | Secondary/metadata text |

Fonts are all macOS system-installed (Helvetica Neue, San Francisco, SF Mono) — no
bundled or downloaded fonts.

## Spacing

`4 · 8 · 12 · 16 · 24 · 32 · 48` (xs → xxxl), plus one special case:
`controlGutter` = `10pt`, the gap between transport buttons — tighter than the
general scale so the row reads as one physical control cluster.

## Corner radius

Deliberately squared, not pill-shaped — the brief asks for buttons that look
pressed, not tinted.

| Token | Value | Used for |
| --- | --- | --- |
| `panel` | 10pt | Window sections, cards |
| `control` | 6pt | Buttons, text fields |
| `recessed` | 4pt | Meter well, counter window |
| `none` | 0pt | Hairline dividers |

## Border

`hairline` is 1pt. A seam (`seamTotal`) is 2pt total: `seam` = 1pt highlight
directly above `seam` = 1pt shadow (see Color above — this is drawn as two lines,
never a single stroke). `focusRing` is 2pt — standard keyboard-focus visibility,
required for VoiceOver/keyboard navigation compliance, and now rendered in
`accentNeutral` rather than system blue.

## Shadow

| Token | Value | Used for |
| --- | --- | --- |
| `panelElevation` | black 14%, blur 8, y+2 | A panel lifted slightly off the canvas |
| `buttonRest` | black 20%, blur 1, y+1 | Resting button — subtle grounding |
| `pressedOverlayOpacity` | 0.12 | Darkening overlay simulating an inset shadow on press (SwiftUI has no cheap true inset shadow) |

## State

| Token | Value | Used for |
| --- | --- | --- |
| `disabledOpacity` | 0.35 | Disabled controls — opacity only, no desaturation pass (the palette is already neutral) |

## VU meter geometry

Position/zone geometry for the level meter face. Ballistics (how the needle
*moves*) are in Motion, below — this section is only the static dial.

| Token | Value | Meaning |
| --- | --- | --- |
| `arcSweepDegrees` | 80° | Total needle travel from rest to full scale |
| `arcRestDegrees` | -40° | Needle angle at zero level, measured from vertical |
| `greenZoneEnd` | 0.75 | Fraction of the scale where green ends and amber begins |
| `amberZoneEnd` | 1.0 | Amber continues to the top of the scale — there is no red clip zone; the app's one red stays reserved for the record light |
| `majorTickCount` | 5 | Numbered ticks across the face |
| `minorTicksPerMajor` | 3 | Unlabeled ticks between each major tick |

## Motion

Values match the emil-design-eng framework applied to this app:

| Token | Value | Rule |
| --- | --- | --- |
| `instant` | 0ms | Anything triggered by the hotkey or another keyboard action (the pill, meter arming, recording-state text) — no animation, full stop |
| `buttonPress` | 120ms | Button depress |
| `buttonRelease` | 160ms | Button release — snappy |
| `ui` | 220ms | Standard enter/exit: list rows, popovers, Settings sheet |
| `needleSmoothingTimeConstantMs` | 300ms | VU meter needle response |

Easing: `ease-out` (`cubic-bezier(0.23, 1, 0.32, 1)`) for anything entering or
appearing; `ease-in-out` (`cubic-bezier(0.77, 0, 0.175, 1)`) for on-screen movement.
Never `ease-in` on UI. Only `transform` and `opacity` are animated.
`prefers-reduced-motion` (AppKit: `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`)
is respected everywhere except the needle, which keeps functioning but drops
overshoot/bounce.

**Needle, specifically:** the needle tracks a continuously-changing input (live
mic level), not a single destination value, so it is **not** driven by a timed
`Animation`/easing curve. It's per-frame exponential smoothing instead:

```
displayed += (target - displayed) * (1 - exp(-dt / (needleSmoothingTimeConstantMs / 1000)))
```

run once per audio tick. A timed easing animation would retarget and stutter every
time the input changes mid-flight, which for a meter reading real audio is
constantly.
