import AVFoundation

/// Abstraction over a speech-to-text engine. `AppleSpeechTranscriber` is
/// the only implementation in the skeleton; this seam is what lets
/// whisper.cpp or Parakeet drop in later as a sibling rather than a
/// rewrite.
public protocol Transcriber: AnyObject {
    /// Resolve locale/asset availability. Call once before `start()`.
    func prepare() async throws

    /// The audio format this transcriber wants fed into it via `feed`.
    /// `AudioCapture` converts to this format before delivery.
    func preferredAudioFormat() async -> AVAudioFormat?

    /// Begin a recognition session.
    func start() async throws

    /// Feed one buffer of audio, already in `preferredAudioFormat`.
    func feed(_ buffer: AVAudioPCMBuffer)

    /// Live, not-yet-final transcript text, for HUD display.
    var partials: AsyncStream<String> { get }

    /// Signal end of input and return the final transcript.
    func finishAndTranscribe() async throws -> String

    /// Abort the in-flight session without producing a result.
    func cancel() async
}

public enum TranscriberError: Error {
    case unsupportedLocale
    case noAudioFormat
    case notStarted
}
