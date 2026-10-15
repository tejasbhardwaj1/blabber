import SwiftUI

/// SwiftUI app entry point. Owns the main window and Settings scenes; the
/// hotkey/audio/transcription pipeline and shared `AppModel` live in
/// `AppDelegate`, installed via `NSApplicationDelegateAdaptor` so they
/// keep running — and the menu bar item stays up — independent of whether
/// any window is open.
///
/// No `.tint` override: the user's system accent color drives every
/// control and selection.
@main
struct BlabberMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(appDelegate: appDelegate)
        }
        .defaultSize(width: 760, height: 560)

        Settings {
            SettingsView(appDelegate: appDelegate)
        }
    }
}
