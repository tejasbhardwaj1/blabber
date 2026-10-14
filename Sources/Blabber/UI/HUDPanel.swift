import AppKit

/// A small always-on-top indicator shown while recording.
///
/// `isNonactivatingPanel` is not optional here: if the HUD takes key
/// focus, the synthesized ⌘V in `TextInjector` lands in the HUD instead
/// of the document the user was dictating into. This is a documented
/// failure mode in other dictation apps.
final class HUDPanel: NSPanel {
    private let label = NSTextField(labelWithString: "● Listening")

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 44),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        let visualEffect = NSVisualEffectView(frame: contentRect(forFrameRect: frame))
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true

        label.alignment = .center
        label.textColor = NSColor(red: 1.0, green: 0.36, blue: 0.28, alpha: 1.0) // coral accent
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.frame = visualEffect.bounds

        visualEffect.addSubview(label)
        contentView = visualEffect

        positionBottomCenter()
    }

    func setStatus(_ text: String) {
        label.stringValue = text
    }

    func show() {
        positionBottomCenter()
        orderFrontRegardless()
    }

    func hide() {
        orderOut(nil)
    }

    private func positionBottomCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        let y = screenFrame.minY + 80
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
