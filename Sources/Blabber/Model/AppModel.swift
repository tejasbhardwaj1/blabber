import Foundation
import Observation

/// Single source of truth for the SwiftUI interface.
///
/// Owned by `AppDelegate`, which drives recording / level / notice state
/// from the audio + transcription pipeline. Views read this object and
/// call back through `onToggleRecording` for the on-screen Start/Stop
/// button. State mutated from the pipeline is applied on the main actor.
@MainActor
@Observable
final class AppModel {
    /// Saved dictations, newest first.
    private(set) var records: [TranscriptionRecord] = []

    /// True while the mic is open. Set without animation so it reflects
    /// a hotkey press instantly.
    var isRecording = false

    /// When the current recording began, for the elapsed-time readout.
    var recordingStartedAt: Date?

    /// Recent mic levels (0...1), oldest → newest, for the live meter.
    /// Bounded to `maxLevels`; only updated while recording.
    private(set) var levels: [Float] = []

    /// A transient line shown under the recorder — e.g. after a dictation
    /// was copied to the clipboard rather than pasted. Cleared when a new
    /// recording starts.
    var notice: String?

    /// Read-only description of the active speech model, for Settings.
    var modelInfo: ModelInfo?

    /// Set by `AppDelegate`; invoked by the Start/Stop button.
    var onToggleRecording: (() -> Void)?

    private let store = HistoryStore()
    private let maxLevels = 48

    /// A light peak-with-decay smoothing so the meter reads as a lively
    /// bar display rather than raw per-buffer noise. Not a VU ballistic —
    /// just signal conditioning for legibility.
    private var smoothedLevel: Float = 0

    init() {
        records = store.load()
    }

    func toggleRecording() {
        onToggleRecording?()
    }

    func beganRecording(at date: Date) {
        notice = nil
        recordingStartedAt = date
        levels = []
        smoothedLevel = 0
        isRecording = true
    }

    func stoppedRecording() {
        isRecording = false
        recordingStartedAt = nil
        levels = []
    }

    func appendLevel(_ level: Float) {
        // Fast attack, slower release.
        smoothedLevel = level > smoothedLevel
            ? level
            : smoothedLevel * 0.82 + level * 0.18
        levels.append(smoothedLevel)
        if levels.count > maxLevels {
            levels.removeFirst(levels.count - maxLevels)
        }
    }

    func add(_ record: TranscriptionRecord) {
        records.insert(record, at: 0)
        store.save(records)
    }
}

/// What Settings shows about the on-device speech model. Everything here
/// is derived from what already exists today — no invented options.
struct ModelInfo: Equatable {
    var name: String
    var language: String
    var status: String
}
