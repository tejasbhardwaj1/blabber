import AppKit

/// Menu bar presence kept while Blabber is a regular (Dock-visible) app.
/// Secondary to the main window: status, start/stop, open window, quit.
final class MenuBarController {
    // NSVariableStatusItemLength is a C global constant (-1.0) that
    // doesn't bridge into the Swift AppKit module interface under
    // this SDK; use its documented raw value directly.
    private let statusItem = NSStatusBar.system.statusItem(withLength: -1)

    private let statusLineItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
    private let toggleRecordingItem = NSMenuItem(title: "Start Dictation", action: #selector(toggleRecording), keyEquivalent: "")

    var onQuit: (() -> Void)?
    var onOpenWindow: (() -> Void)?
    var onToggleRecording: (() -> Void)?

    init() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Blabber")
            button.image?.isTemplate = true
        }

        statusLineItem.isEnabled = false

        let menu = NSMenu()
        menu.addItem(statusLineItem)
        menu.addItem(.separator())

        toggleRecordingItem.target = self
        menu.addItem(toggleRecordingItem)

        let openItem = NSMenuItem(title: "Open Blabber", action: #selector(openWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Blabber", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func setRecording(_ recording: Bool) {
        statusItem.button?.image = NSImage(
            systemSymbolName: recording ? "waveform.circle.fill" : "waveform",
            accessibilityDescription: "Blabber"
        )
        statusItem.button?.image?.isTemplate = !recording
        toggleRecordingItem.title = recording ? "Stop Dictation" : "Start Dictation"
        setStatusText(recording ? "Listening…" : "Ready")
    }

    func setStatusText(_ text: String) {
        statusLineItem.title = text
    }

    @objc private func toggleRecording() {
        onToggleRecording?()
    }

    @objc private func openWindow() {
        onOpenWindow?()
    }

    @objc private func quit() {
        onQuit?()
    }
}
