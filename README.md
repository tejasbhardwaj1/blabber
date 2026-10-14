# Blabber

A native macOS push-to-talk dictation app. Hold a hotkey, speak, release — the transcribed, lightly cleaned-up text is typed at your cursor in whatever app you're using.

Built as a thin stack of system frameworks rather than a wrapped web app: a listen-only `CGEventTap` for the hotkey, `AVAudioEngine` for capture, macOS 26's on-device `SpeechAnalyzer`/`SpeechTranscriber` for transcription (fully offline, no cloud round-trip), and the Accessibility API with a clipboard fallback for injecting text into the focused app.

## Requirements

- macOS 26 (Tahoe) or later, Apple Silicon
- Command Line Tools for Xcode 26.6+ (`xcrun --show-sdk-version` should report 26.x — the macOS 15.x SDK is missing `SpeechTranscriber`/`FoundationModels`)
- A stable local code-signing identity (see Setup below) — without one, macOS resets Microphone/Input Monitoring/Accessibility grants on every rebuild

## Setup

```sh
# One-time: generate a self-signed "Blabber Dev Signing" certificate.
# This keeps TCC permission grants stable across rebuilds.
./Scripts/make-cert.sh

# One-time: render the app icon.
make icon
```

Grant Blabber **Microphone**, **Input Monitoring**, and **Accessibility** in
System Settings → Privacy & Security the first time you run it.

## Build & run

```sh
make run       # release build, bundles Blabber.app, signs it, launches it
```

Other targets:

```sh
make build     # just the release binary
make bundle    # build + assemble Blabber.app + sign (no launch)
make test      # run the pure-logic self-check (see note below)
make clean     # remove build artifacts
```

Hold **Right ⌘** anywhere to dictate.

### Why `make test`, not `swift test`

`swift test` builds cleanly on this CLT-only toolchain but silently does
not execute — the test bundle reports success even against a
deliberately broken assertion, with no diagnostic. `Sources/SelfCheck`
is a plain executable that runs the same checks against the same
`BlabberCore` library and actually verifies failures are caught. The
`Testing`-based suites in `Tests/BlabberTests` remain the intended
long-term test suite once a full Xcode toolchain is available.

## Project layout

```
Sources/BlabberCore/   Hotkey, audio, transcription, formatting, injection, permissions
Sources/Blabber/       App shell: menu bar, HUD, app delegate wiring
Sources/SelfCheck/     Standalone logic verifier (see above)
Tests/BlabberTests/    Testing-framework suites
Resources/             Info.plist, entitlements, icon
Scripts/               Cert generation, icon rendering
```
