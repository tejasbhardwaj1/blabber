import SwiftUI

/// Settings scene (Cmd+,). Shows only what exists today: the push-to-talk
/// shortcut and the on-device speech model.
struct SettingsView: View {
    let appDelegate: AppDelegate

    var body: some View {
        Form {
            Section("Dictation Shortcut") {
                LabeledContent("Push-to-talk") {
                    ShortcutBadge(keys: ["⌘"], caption: "Right")
                }
                Text("Hold the key anywhere to dictate. This shortcut is fixed in this version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Speech Model") {
                let info = appDelegate.model.modelInfo
                LabeledContent("Model", value: info?.name ?? "—")
                LabeledContent("Language", value: info?.language ?? "—")
                LabeledContent("Status", value: info?.status ?? "—")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A read-only shortcut field styled like the standard macOS shortcut
/// recorder. It displays the current (fixed) binding; it does not capture
/// a new one, because rebinding would require changing the hotkey tap.
private struct ShortcutBadge: View {
    let keys: [String]
    let caption: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.body)
                    .frame(minWidth: 22, minHeight: 22)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                            .fill(.quaternary)
                    )
            }
            Text(caption)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Push-to-talk shortcut: Right Command")
    }
}
