import AppKit
import AVFoundation
import BlabberCore
import os

/// Owns the hotkey/audio/transcription/injection pipeline and the
/// background surfaces (menu bar item, HUD pill) that stay available
/// while Blabber's main window is closed. Installed via
/// `NSApplicationDelegateAdaptor` from `BlabberMain`, which owns the
/// SwiftUI window and Settings scenes.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "app")

    private let hotkey = HotkeyEngine()
    private let pushToTalk = PushToTalkState()
    private let audio = AudioCapture()
    private var transcriber: AppleSpeechTranscriber?
    private let injector = TextInjector()
    private let formatter = RulesFormatter()

    private var menuBar: MenuBarController!
    private var hud: HUDPanel!

    private var isEngineReady = false
    private var isRecording = false

    /// Set by `BlabberMain`'s window content once it's established, so
    /// the menu bar's "Open Blabber" item can bring the (SwiftUI-owned)
    /// main window back after the user closes it.
    var openMainWindowAction: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController()
        menuBar.onQuit = { NSApplication.shared.terminate(nil) }
        menuBar.onOpenWindow = { [weak self] in self?.openMainWindowAction?() }
        menuBar.onToggleRecording = { [weak self] in self?.toggleManualRecording() }
        hud = HUDPanel()

        requestPermissionsThenStart()
    }

    /// Blabber keeps running (menu bar item, hotkey) after the main
    /// window is closed — closing the window is not the same as
    /// quitting a background utility like this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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
                }
            }
        default:
            log.error("Microphone permission not authorized (\(Permissions.microphoneStatus().rawValue, privacy: .public)). Grant it in System Settings > Privacy & Security > Microphone.")
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
                let transcriber = AppleSpeechTranscriber()
                try await transcriber.prepare()
                self.transcriber = transcriber

                guard let format = await transcriber.preferredAudioFormat() else {
                    log.error("No compatible audio format available from SpeechAnalyzer.")
                    return
                }

                try audio.start(targetFormat: format) { [weak self] buffer in
                    self?.transcriber?.feed(buffer)
                }

                isEngineReady = true
                installHotkey()
                menuBar.setStatusText("Ready")
                log.info("Blabber ready. Hold Right ⌘ to dictate.")
            } catch {
                log.error("Bootstrap failed: \(error.localizedDescription, privacy: .public)")
                menuBar.setStatusText("Engine failed to start")
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

    /// Menu-bar "Start/Stop Dictation" — a toggle, independent of the
    /// push-to-talk hotkey. Ignored if a hotkey-driven recording is
    /// already in flight, and vice versa: `isRecording` is the one
    /// guard shared by both entry points.
    private func toggleManualRecording() {
        if isRecording {
            finishDictation()
        } else {
            beginDictation()
        }
    }

    private func beginDictation() {
        guard isEngineReady, let transcriber, !isRecording else { return }
        isRecording = true
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
        guard isRecording else { return }
        isRecording = false
        audio.endRecording()
        menuBar.setRecording(false)
        hud.hide()
        Task { await transcriber?.cancel() }
    }

    private func finishDictation() {
        guard isRecording else { return }
        isRecording = false
        audio.endRecording()
        menuBar.setRecording(false)
        hud.setStatus("… Transcribing")

        Task {
            do {
                guard let transcriber else { return }
                let rawText = try await transcriber.finishAndTranscribe()
                let formatted = formatter.apply(rawText, context: FormatContext(frontmostBundleID: frontmostBundleID()))
                hud.hide()

                if !formatted.isEmpty {
                    let result = injector.inject(formatted)
                    log.info("Injected via \(String(describing: result), privacy: .public): \"\(formatted, privacy: .private)\"")
                }
            } catch {
                log.error("Transcription failed: \(error.localizedDescription, privacy: .public)")
                hud.hide()
            }
        }
    }

    private func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
