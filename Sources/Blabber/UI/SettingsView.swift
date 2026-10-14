import SwiftUI

/// Phase B placeholder for the Settings scene (Cmd+,). Replaced in
/// Phase D by the hotkey recorder and model/language/asset-status
/// controls described in the brief — nothing invented ahead of that.
struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Settings")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Text("Hotkey and model settings land here in Phase D.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Color.textSecondary)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 420, height: 200)
        .background(DesignTokens.Color.bgCanvas)
    }
}
