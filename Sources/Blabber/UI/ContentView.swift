import SwiftUI

/// Phase B placeholder for the main window. Replaced in Phase D by the
/// real layout: history (searchable, with per-row copy), the live VU
/// meter, start/stop, and the Dictionary.
struct ContentView: View {
    let appDelegate: AppDelegate

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Blabber")
                .font(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Text("Hold Right ⌘ anywhere to dictate.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Color.textSecondary)
            Text("History, the level meter, and the Dictionary land here in Phase D.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Color.bgCanvas)
        .onAppear {
            // Routes the menu bar's "Open Blabber" item through SwiftUI's
            // own window-opening machinery, so it reliably recreates the
            // window even after the user has fully closed it — not just
            // a `makeKeyAndOrderFront` on a window that may no longer
            // exist.
            appDelegate.openMainWindowAction = { openWindow(id: "main") }
        }
    }
}
