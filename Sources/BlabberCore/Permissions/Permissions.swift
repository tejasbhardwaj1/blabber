import ApplicationServices
import AVFoundation
import CoreGraphics
import Foundation

/// Centralizes the three permissions Blabber needs. Each one is a
/// separate TCC bucket on macOS — granting one does not imply the others.
public enum Permissions {

    /// Input Monitoring. Required to see key events system-wide via
    /// CGEventTap, even a listen-only one. Separate from Accessibility.
    public static func hasInputMonitoring() -> Bool {
        CGPreflightListenEventAccess()
    }

    public static func requestInputMonitoring() {
        CGRequestListenEventAccess()
    }

    /// Accessibility. Required to read/write the focused UI element
    /// (AXUIElement) and to post synthetic keyboard events for the
    /// clipboard-paste injection fallback.
    public static func hasAccessibility() -> Bool {
        AXIsProcessTrusted()
    }

    public static func requestAccessibility() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Microphone. Required to capture audio for transcription.
    public static func microphoneStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    public static func requestMicrophone(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    public static var allGranted: Bool {
        hasInputMonitoring() && hasAccessibility() && microphoneStatus() == .authorized
    }
}
