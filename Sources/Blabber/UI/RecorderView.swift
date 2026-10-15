import SwiftUI

/// The recorder at the top of History: a record dot + elapsed timer, the
/// live level meter, and a prominent Start/Stop button. Starting via the
/// hotkey updates `model.isRecording` with no animation, so this appears
/// instantly.
struct RecorderView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if model.isRecording {
                        Circle()
                            .fill(DesignTokens.Color.recordIndicator)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)
                    }
                    TimerLabel(startedAt: model.recordingStartedAt)
                }

                Spacer()

                Button {
                    model.toggleRecording()
                } label: {
                    Label(
                        model.isRecording ? "Stop" : "Start Dictation",
                        systemImage: model.isRecording ? "stop.fill" : "mic.fill"
                    )
                    .frame(minWidth: 96)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            LevelMeterView(levels: model.levels, isActive: model.isRecording)

            if let notice = model.notice {
                Text(notice)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.regularMaterial)
    }
}

/// Elapsed-time readout. Ticks via `TimelineView` while recording; shows
/// `00:00` at rest. Monospaced digits keep the width stable.
private struct TimerLabel: View {
    let startedAt: Date?

    var body: some View {
        Group {
            if let startedAt {
                TimelineView(.periodic(from: startedAt, by: 1)) { context in
                    Text(Self.string(from: startedAt, to: context.date))
                }
            } else {
                Text("00:00")
            }
        }
        .font(DesignTokens.Typography.timer)
        .foregroundStyle(startedAt == nil ? .secondary : .primary)
        .accessibilityLabel(startedAt == nil ? "Not recording" : "Recording time")
    }

    private static func string(from start: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
