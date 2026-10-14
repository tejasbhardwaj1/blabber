import AppKit
import ApplicationServices
import Carbon.HIToolbox
import os

/// Delivers transcribed text to whatever has keyboard focus.
///
/// Tier 1: write directly into the focused AXUIElement's selected-text
/// attribute, then read it back to confirm the write actually took —
/// many apps accept the call and silently ignore it.
/// Tier 2: clipboard save → write transient text → synthesize ⌘V →
/// restore the original clipboard.
///
/// A secure-input guard runs before either tier: dictating into a
/// password field is the one failure mode worse than doing nothing.
public final class TextInjector {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "inject")

    public enum InjectResult {
        case ax
        case paste
        case blockedSecureInput
        case failed
    }

    public init() {}

    @discardableResult
    public func inject(_ text: String) -> InjectResult {
        guard !text.isEmpty else { return .failed }

        if isSecureInputActive() {
            log.warning("Secure input active; refusing to inject.")
            return .blockedSecureInput
        }

        if injectViaAccessibility(text) {
            return .ax
        }

        if injectViaPasteboard(text) {
            return .paste
        }

        log.error("All injection tiers failed; leaving text on clipboard.")
        writeToPasteboard(text)
        return .failed
    }

    // MARK: - Secure input guard

    private func isSecureInputActive() -> Bool {
        IsSecureEventInputEnabled()
    }

    // MARK: - Tier 1: Accessibility

    private func injectViaAccessibility(_ text: String) -> Bool {
        guard Permissions.hasAccessibility() else { return false }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef)
        guard focusResult == .success, let focused = focusedRef else { return false }
        let element = focused as! AXUIElement

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String

        let textRoles: Set<String> = [
            kAXTextFieldRole as String,
            kAXTextAreaRole as String,
            kAXComboBoxRole as String,
        ]
        guard let role, textRoles.contains(role) else { return false }

        let setResult = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
        guard setResult == .success else { return false }

        // Verify the write actually landed — some apps accept it and
        // ignore it without returning an error.
        var confirmRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &confirmRef)
        if let confirmedValue = confirmRef as? String, confirmedValue.contains(text) {
            return true
        }
        // Even without full confirmation, a successful `.success` set
        // result on a plain text role is usually trustworthy enough —
        // but we only count it as AX success when we could verify.
        return false
    }

    // MARK: - Tier 2: Clipboard + synthesized ⌘V

    private func injectViaPasteboard(_ text: String) -> Bool {
        guard Permissions.hasAccessibility() else { return false }

        let pasteboard = NSPasteboard.general
        let savedItems = snapshotPasteboard(pasteboard)

        writeToPasteboard(text)

        postCommandV()

        // Give the target app a moment to read the pasteboard before
        // restoring the user's prior clipboard contents.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.restorePasteboard(pasteboard, items: savedItems)
        }

        return true
    }

    private func writeToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Mark as a transient, concealed write so well-behaved clipboard
        // managers skip recording it in history.
        pasteboard.setString("true", forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
        pasteboard.setString("true", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
    }

    private func snapshotPasteboard(_ pasteboard: NSPasteboard) -> [(NSPasteboard.PasteboardType, Data)] {
        var items: [(NSPasteboard.PasteboardType, Data)] = []
        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                items.append((type, data))
            }
        }
        return items
    }

    private func restorePasteboard(_ pasteboard: NSPasteboard, items: [(NSPasteboard.PasteboardType, Data)]) {
        pasteboard.clearContents()
        for (type, data) in items {
            pasteboard.setData(data, forType: type)
        }
    }

    private func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 9 // 'v'

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            log.error("Failed to create synthetic ⌘V events.")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }
}
