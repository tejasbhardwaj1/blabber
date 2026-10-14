import SwiftUI

/// SwiftUI app entry point. Owns the main window and Settings scenes;
/// the hotkey/audio/transcription pipeline lives in `AppDelegate`,
/// installed below via `NSApplicationDelegateAdaptor` so it keeps
/// running — and the menu bar item stays up — independent of whether
/// any window is open.
@main
struct BlabberMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(appDelegate: appDelegate)
                .tint(DesignTokens.Color.accentNeutral)
        }
        .defaultSize(width: 720, height: 520)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .tint(DesignTokens.Color.accentNeutral)
        }
    }
}
