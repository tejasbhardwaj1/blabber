import AppKit
import AVFoundation
import BlabberCore
import os

/// Owns the hotkey/audio/transcription/injection pipeline, the shared
/// `AppModel` the SwiftUI interface reads, and the background surfaces
/// (menu bar item, HUD) that stay available while the main window is
/// closed. Installed via `NSApplicationDelegateAdaptor` from
/// `BlabberMain`, which owns the window and Settings scenes.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "app")

    /// Shared state for the SwiftUI views. Created eagerly so the scene
    /// body can read it before `applicationDidFinishLaunching` runs.
    let model = AppModel()

    private let hotkey = HotkeyEngine()
    private let pushToTalk = PushToTalkState()
    private let audio = AudioCapture()
    private var transcriber: AppleSpeechTranscriber?
    private let injector = TextInjector()
    private let formatter = RulesFormatter()

    private var menuBar: MenuBarController!
    private var hud: HUDPanel!

    private var isEngineReady = false

    private static let selfBundleID = "com.tejas.blabber"
    private let localeIdentifier = "en-US"

    /// Set by the window content once it's established, so the menu bar's
    /// "Open Blabber" item can reopen the SwiftUI-owned main window.
    var openMainWindowAction: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController()
        menuBar.onQuit = { NSApplication.shared.terminate(nil) }
        menuBar.onOpenWindow = { [weak self] in self?.openMainWindowAction?() }
        menuBar.onToggleRecording = { [weak self] in self?.toggleRecording() }
        hud = HUDPanel()

        model.onToggleRecording = { [weak self] in self?.toggleRecording() }
        model.modelInfo = ModelInfo(
            name: "Apple on-device dictation",
            language: Self.languageName(for: localeIdentifier),
            status: "Preparing…"
        )

        audio.onLevel = { [weak self] level in
            // Hop to the main actor; the tap runs on the audio thread.
            Task { @MainActor in
                guard let self, self.model.isRecording else { return }
                self.model.appendLevel(level)
            }
        }

        requestPermissionsThenStart()
    }

    /// Blabber keeps running (menu bar item, hotkey) after the main
    /// window is closed — closing the window isn't the same as quitting a
    /// background utility like this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Clicking the Dock icon (or reopening the app) when no window is
    /// open brings the main window back, rather than just re-activating a
    /// windowless app.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { openMainWindowAction?() }
        return true
    }

    private func requestPermissionsThenStart() {
        if !Permissions.hasAccessibility() {
            log.warning("Requesting Accessibility permission...")
            Permissions.requestAccessibility()
        }
        if !Permissions.hasInputMonitoring() {
            log.warning("Requesting Input Monitoring permission...")
            Permissions.requestInputMonitoring()
        }

        switch Permissions.microphoneStatus() {
        case .authorized:
            bootstrap()
        case .notDetermined:
            Permissions.requestMicrophone { [weak self] granted in
                if granted {
                    self?.bootstrap()
                } else {
                    self?.log.error("Microphone permission denied.")
                    self?.model.modelInfo?.status = "Microphone access denied"
                }
            }
        default:
            log.error("Microphone permission not authorized (\(Permissions.microphoneStatus().rawValue, privacy: .public)). Grant it in System Settings > Privacy & Security > Microphone.")
            model.modelInfo?.status = "Microphone access needed"
            // Retry shortly — permission dialogs/settings changes can land
            // after this check runs.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.requestPermissionsThenStart()
            }
        }
    }

    private func bootstrap() {
        Task {
            do {
                let transcriber = AppleSpeechTranscriber(locale: Locale(identifier: localeIdentifier))
                try await transcriber.prepare()
                self.transcriber = transcriber

                guard let format = await transcriber.preferredAudioFormat() else {
                    log.error("No compatible audio format available from SpeechAnalyzer.")
                    model.modelInfo?.status = "Unavailable"
                    return
                }

                try audio.start(targetFormat: format) { [weak self] buffer in
                    self?.transcriber?.feed(buffer)
                }

                isEngineReady = true
                installHotkey()
                menuBar.setStatusText("Ready")
                model.modelInfo?.status = "Ready"
                log.info("Blabber ready. Hold Right ⌘ to dictate.")
            } catch {
                log.error("Bootstrap failed: \(error.localizedDescription, privacy: .public)")
                menuBar.setStatusText("Engine failed to start")
                model.modelInfo?.status = "Unavailable"
            }
        }
    }

    private func installHotkey() {
        hotkey.onEvent = { [weak self] event in
            self?.handleHotkeyEvent(event)
        }
        if !hotkey.start() {
            log.error("Could not install hotkey tap. Check Input Monitoring permission.")
        }
    }

    private func handleHotkeyEvent(_ event: HotkeyEvent) {
        let action = pushToTalk.handle(event)
        switch action {
        case .startRecording:
            beginDictation()
        case .cancelRecording:
            cancelDictation()
        case .finishRecording:
            finishDictation()
        case .none:
            break
        }
    }

    /// On-screen Start/Stop — a toggle, independent of the push-to-talk
    /// hotkey. `model.isRecording` is the one guard shared by both entry
    /// points, so they can't collide.
    private func toggleRecording() {
        if model.isRecording {
            finishDictation()
        } else {
            beginDictation()
        }
    }

    private func beginDictation() {
        guard isEngineReady, let transcriber, !model.isRecording else { return }
        model.beganRecording(at: Date())
        menuBar.setRecording(true)
        hud.setStatus("● Listening")
        hud.show()
        audio.beginRecording()

        Task {
            do {
                try await transcriber.start()
            } catch {
                log.error("Failed to start transcriber: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func cancelDictation() {
        guard model.isRecording else { return }
        model.stoppedRecording()
        audio.endRecording()
        menuBar.setRecording(false)
        hud.hide()
        Task { await transcriber?.cancel() }
    }

    private func finishDictation() {
        guard model.isRecording else { return }
        // Capture who's frontmost at the moment recording ends — this is
        // what decides paste-vs-copy, and it must be read before any
        // window activation can change it.
        let blabberFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Self.selfBundleID

        model.stoppedRecording()
        audio.endRecording()
        menuBar.setRecording(false)
        hud.setStatus("… Transcribing")

        Task {
            do {
                guard let transcriber else { return }
                let rawText = try await transcriber.finishAndTranscribe()
                let formatted = formatter.apply(rawText, context: FormatContext(frontmostBundleID: frontmostBundleID()))
                hud.hide()

                guard !formatted.isEmpty else {
                    model.notice = "No speech detected."
                    return
                }

                model.add(TranscriptionRecord(text: formatted, original: rawText))

                if blabberFrontmost {
                    // Pasting into Blabber itself makes no sense — save it
                    // to history and the clipboard, and say so.
                    copyToClipboard(formatted)
                    model.notice = "Saved to history and copied to the clipboard."
                } else {
                    let result = injector.inject(formatted)
                    log.info("Injected via \(String(describing: result), privacy: .public): \"\(formatted, privacy: .private)\"")
                    model.notice = Self.notice(for: result)
                }
            } catch {
                log.error("Transcription failed: \(error.localizedDescription, privacy: .public)")
                hud.hide()
                model.notice = "Transcription failed."
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private static func notice(for result: TextInjector.InjectResult) -> String? {
        switch result {
        case .ax, .paste:
            return nil // Inserted into the active app; no notice needed.
        case .blockedSecureInput:
            return "A password field was focused, so nothing was inserted. Saved to history."
        case .failed:
            return "Couldn't insert the text. It's saved to history and on the clipboard."
        }
    }

    private func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private static func languageName(for identifier: String) -> String {
        Locale.current.localizedString(forIdentifier: identifier) ?? identifier
    }
}
