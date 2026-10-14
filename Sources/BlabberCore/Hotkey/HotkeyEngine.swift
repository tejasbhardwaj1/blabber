import CoreGraphics
import Foundation
import os

/// Events the push-to-talk state machine cares about. Deliberately a
/// narrow set — the engine filters everything else out before it ever
/// reaches application code.
public enum HotkeyEvent {
    case down
    case up
    case escape
}

/// Listens system-wide for the push-to-talk key using a *listen-only*
/// CGEventTap.
///
/// Why listen-only, and why CGEventTap at all:
/// - `NSEvent.addGlobalMonitorForEvents` cannot reliably distinguish
///   left/right modifier keys and has a reported bus-error crash on
///   macOS 26 in `GlobalObserverHandler`.
/// - fn and modifier-only keys (right-⌘, right-⌥) surface as
///   `flagsChanged`, not `keyDown` — a tap is the only way to see the
///   raw flag transitions.
/// - A *listen-only* tap can never wedge system input if Input
///   Monitoring is revoked mid-session — this app never needs to
///   swallow the key, only observe it.
public final class HotkeyEngine {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "hotkey")

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// The modifier flag and keycode this engine watches for.
    /// Default: right-⌘ (keycode 54). Deliberately not fn — macOS
    /// already binds double-fn to its own dictation, and some other
    /// apps default to fn too.
    public var watchedKeyCode: CGKeyCode = 54
    public var watchedFlagMask: CGEventFlags = .maskCommand

    private var isKeyCurrentlyDown = false

    /// Fired on the main thread. The tap callback runs on whatever
    /// thread owns the tap's run loop, so every dispatch here hops to
    /// main before touching this value.
    public var onEvent: ((HotkeyEvent) -> Void)?

    public init() {}

    public func start() -> Bool {
        guard Permissions.hasInputMonitoring() else {
            log.warning("Input Monitoring not granted; hotkey tap not installed.")
            return false
        }

        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passRetained(event) }
            let engine = Unmanaged<HotkeyEngine>.fromOpaque(refcon).takeUnretainedValue()
            engine.handle(type: type, event: event)
            // Listen-only: always pass the event through untouched.
            return Unmanaged.passRetained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: refcon
        ) else {
            log.error("Failed to create event tap.")
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        log.info("Hotkey tap installed.")
        return true
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) {
        // The system disables a tap on timeout or misbehaving callback;
        // re-enable immediately or the hotkey silently stops working.
        if type.rawValue == UInt32(CGEventType.tapDisabledByTimeout.rawValue) ||
            type.rawValue == UInt32(CGEventType.tapDisabledByUserInput.rawValue) {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return
        }

        if type == .keyDown {
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == 53 { // Escape
                dispatch(.escape)
            }
            return
        }

        guard type == .flagsChanged else { return }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard keyCode == watchedKeyCode else { return }

        let flags = event.flags
        let isDown = flags.contains(watchedFlagMask)

        if isDown && !isKeyCurrentlyDown {
            isKeyCurrentlyDown = true
            dispatch(.down)
        } else if !isDown && isKeyCurrentlyDown {
            isKeyCurrentlyDown = false
            dispatch(.up)
        }
    }

    private func dispatch(_ event: HotkeyEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.onEvent?(event)
        }
    }
}
