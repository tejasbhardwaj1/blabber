import AVFoundation
import os

/// Captures microphone audio and delivers it already converted to the
/// format a `Transcriber` asks for.
///
/// The engine is started once at app launch and kept warm — starting it
/// fresh on every keypress costs 100-300ms and clips the first syllable.
/// Buffers are simply dropped on the floor while not recording.
///
/// The conversion step is not optional: `AVAudioEngine`'s input node
/// format (48kHz on this hardware) essentially never matches what
/// `SpeechAnalyzer.bestAvailableAudioFormat` wants. Feeding mismatched
/// buffers compiles and runs without error and produces an empty
/// transcript — there is no exception to catch. Treat the RMS log in
/// `feed` as load-bearing while bringing this up the first time.
public final class AudioCapture {
    private let log = Logger(subsystem: "com.tejas.blabber", category: "audio")
    private let engine = AVAudioEngine()

    private var targetFormat: AVAudioFormat?
    private var converter: AVAudioConverter?

    private var isRecording = false
    private var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    /// Read-only metering tap. Called on the audio thread with a 0...1
    /// level derived from each buffer while recording, for the live UI
    /// meter. Purely observational: it reads sample values and never
    /// mutates the buffer or the capture/conversion path.
    public var onLevel: ((Float) -> Void)?

    /// Rolling pre-roll so the leading consonant of an utterance isn't
    /// lost to tap/engine startup latency.
    private var preRoll: [AVAudioPCMBuffer] = []
    private let preRollDuration: TimeInterval = 0.3

    public init() {}

    public func start(targetFormat: AVAudioFormat, onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        self.targetFormat = targetFormat
        self.onBuffer = onBuffer

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        log.info("Input format: \(inputFormat.sampleRate, privacy: .public)Hz ch=\(inputFormat.channelCount, privacy: .public)")
        log.info("Target format: \(targetFormat.sampleRate, privacy: .public)Hz ch=\(targetFormat.channelCount, privacy: .public)")

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        if converter == nil {
            log.error("Failed to create AVAudioConverter from input format to target format.")
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.handleRawBuffer(buffer)
        }

        engine.prepare()
        try engine.start()
        log.info("Audio engine started (warm, gated).")
    }

    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    public func beginRecording() {
        isRecording = true
        // Flush pre-roll into the live stream so the key-down moment
        // doesn't clip the start of speech.
        for buffer in preRoll {
            onBuffer?(buffer)
        }
        preRoll.removeAll()
    }

    public func endRecording() {
        isRecording = false
    }

    private func handleRawBuffer(_ raw: AVAudioPCMBuffer) {
        guard let targetFormat, let converter else { return }

        guard let converted = convert(raw, using: converter, to: targetFormat) else {
            log.error("Buffer conversion failed; dropping buffer.")
            return
        }

        if isRecording {
            onBuffer?(converted)
            onLevel?(meterLevel(from: raw))
        } else {
            appendPreRoll(converted)
        }
    }

    /// RMS level of the raw buffer, mapped from roughly -50…0 dBFS to
    /// 0...1 for display. Read-only: iterates sample values, writes
    /// nothing.
    private func meterLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        let samples = channelData[0]
        var sumSquares: Float = 0
        for i in 0..<frameCount {
            let sample = samples[i]
            sumSquares += sample * sample
        }
        let rms = sqrtf(sumSquares / Float(frameCount))
        let db = 20 * log10f(max(rms, 1e-7))
        let clamped = max(-50, min(0, db))
        return (clamped + 50) / 50
    }

    private func appendPreRoll(_ buffer: AVAudioPCMBuffer) {
        preRoll.append(buffer)
        let totalFrames = preRoll.reduce(0.0) { $0 + Double($1.frameLength) / $1.format.sampleRate }
        while totalFrames > preRollDuration, preRoll.count > 1 {
            preRoll.removeFirst()
        }
    }

    private func convert(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: outCapacity) else {
            return nil
        }

        // `convert(to:error:withInputFrom:)` may invoke this block more
        // than once per call if it wants more input than one buffer
        // holds. Supply the buffer exactly once, then signal
        // end-of-stream — otherwise the same buffer is handed back
        // forever and the call never returns.
        var consumed = false
        var error: NSError?
        let status = converter.convert(to: outBuffer, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, error == nil else {
            log.error("Converter error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
            return nil
        }
        return outBuffer
    }
}
