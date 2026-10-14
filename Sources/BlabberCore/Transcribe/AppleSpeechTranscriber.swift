import AVFoundation
import Speech
import os

/// `Transcriber` backed by macOS 26's on-device `SpeechAnalyzer` /
/// `SpeechTranscriber`. The ASR model for en-US is already resident on
/// disk on this machine (`com_apple_MobileAsset_UAF_Speech_...`), so
/// `assetInstallationRequest` is expected to return `nil` in the common
/// case — the install path below exists for locales that aren't
/// pre-downloaded.
///
/// A `SpeechTranscriber` module cannot be rebound to a second
/// `SpeechAnalyzer`: doing so traps inside the framework itself
/// (`EXC_BREAKPOINT` in `SpeechAnalyzer.setWorkers` /
/// `TranscriberCommon.worker.setter`) — not a catchable Swift error, so
/// it takes the whole process down. Confirmed by crash report on the
/// second push-to-talk hold in testing. The fix is structural: `prepare()`
/// resolves locale support, reserves it, and installs assets *once* using
/// a throwaway probe transcriber (also used to cache the audio format,
/// which doesn't change session to session); `start()` then creates a
/// brand new `SpeechTranscriber` + `SpeechAnalyzer` pair for every single
/// dictation.
///
/// Sequencing inside `start()`:
/// 1. Create a fresh `SpeechTranscriber` for this session.
/// 2. Create a fresh `SpeechAnalyzer` wrapping it.
/// 3. Start the analyzer against an `AsyncStream<AnalyzerInput>` and
///    begin feeding buffers.
/// 4. On finish: `finalizeAndFinishThroughEndOfInput()`. Finishing the
///    *input stream* alone does not finish the analyzer session — this
///    call is required or the final result never lands.
public final class AppleSpeechTranscriber: Transcriber {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "transcribe")

    private let requestedLocale: Locale
    private var resolvedLocale: Locale?
    private var cachedAudioFormat: AVAudioFormat?

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?

    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?

    private var accumulatedText = ""
    private let partialsContinuation: AsyncStream<String>.Continuation
    public let partials: AsyncStream<String>

    public init(locale: Locale = Locale(identifier: "en-US")) {
        self.requestedLocale = locale
        var continuation: AsyncStream<String>.Continuation!
        self.partials = AsyncStream { continuation = $0 }
        self.partialsContinuation = continuation
    }

    public func prepare() async throws {
        guard SpeechTranscriber.isAvailable else {
            throw TranscriberError.unsupportedLocale
        }
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: requestedLocale) else {
            throw TranscriberError.unsupportedLocale
        }
        resolvedLocale = locale

        _ = try await AssetInventory.reserve(locale: locale)

        // Probe instance: used only here, to check/install assets and to
        // cache the audio format. Never stored in `self.transcriber` —
        // every dictation session gets its own fresh instance in `start()`.
        let probe = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [probe]) {
            log.info("Installing speech assets for \(locale.identifier, privacy: .public)...")
            try await request.downloadAndInstall()
        }

        cachedAudioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [probe])
    }

    public func preferredAudioFormat() async -> AVAudioFormat? {
        cachedAudioFormat
    }

    public func start() async throws {
        guard let locale = resolvedLocale else { throw TranscriberError.notStarted }

        accumulatedText = ""

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )
        self.transcriber = transcriber

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        resultsTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    self.accumulatedText += text
                    self.partialsContinuation.yield(self.accumulatedText)
                }
            } catch {
                self.log.error("Results stream error: \(error.localizedDescription, privacy: .public)")
            }
        }

        try await analyzer.start(inputSequence: stream)
    }

    public func feed(_ buffer: AVAudioPCMBuffer) {
        inputContinuation?.yield(AnalyzerInput(buffer: buffer))
    }

    public func finishAndTranscribe() async throws -> String {
        guard let analyzer else { throw TranscriberError.notStarted }
        inputContinuation?.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        await resultsTask?.value
        self.analyzer = nil
        self.transcriber = nil
        return accumulatedText
    }

    public func cancel() async {
        inputContinuation?.finish()
        await analyzer?.cancelAndFinishNow()
        resultsTask?.cancel()
        accumulatedText = ""
        self.analyzer = nil
        self.transcriber = nil
    }

    public func teardown() async {
        if let locale = resolvedLocale {
            await AssetInventory.release(reservedLocale: locale)
        }
    }
}
