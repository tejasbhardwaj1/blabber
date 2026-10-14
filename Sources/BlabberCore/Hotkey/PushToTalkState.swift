import Foundation

/// The dictation lifecycle, independent of how the hotkey or audio is
/// implemented. Kept as a plain state machine so it's unit-testable
/// without any system permissions.
public enum DictationState: Equatable {
    case idle
    case recording
    case transcribing
}

public enum PushToTalkAction: Equatable {
    case startRecording
    case cancelRecording
    case finishRecording
    case none
}

/// Turns raw key down/up/escape events into recording start/cancel/finish
/// decisions, applying a minimum-hold threshold so an accidental tap of
/// the hotkey doesn't open the mic and produce a HUD flash for nothing.
public final class PushToTalkState {
    public private(set) var state: DictationState = .idle
    private var keyDownAt: Date?

    /// Taps shorter than this are treated as accidental and cancelled
    /// rather than transcribed.
    public var minimumHoldInterval: TimeInterval = 0.15

    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    public func handle(_ event: HotkeyEvent) -> PushToTalkAction {
        switch (state, event) {
        case (.idle, .down):
            keyDownAt = now()
            state = .recording
            return .startRecording

        case (.recording, .up):
            let held = keyDownAt.map { now().timeIntervalSince($0) } ?? 0
            state = .idle
            keyDownAt = nil
            if held < minimumHoldInterval {
                return .cancelRecording
            }
            return .finishRecording

        case (.recording, .escape):
            state = .idle
            keyDownAt = nil
            return .cancelRecording

        default:
            return .none
        }
    }

    public func reset() {
        state = .idle
        keyDownAt = nil
    }
}
