import Testing
@testable import BlabberCore
import Foundation

@Suite struct PushToTalkStateTests {

    @Test func fullHoldFinishesRecording() {
        var clock = Date(timeIntervalSince1970: 0)
        let state = PushToTalkState(now: { clock })

        #expect(state.handle(.down) == .startRecording)
        clock = clock.addingTimeInterval(1.0)
        #expect(state.handle(.up) == .finishRecording)
        #expect(state.state == .idle)
    }

    @Test func shortTapCancelsInsteadOfFinishing() {
        var clock = Date(timeIntervalSince1970: 0)
        let state = PushToTalkState(now: { clock })
        state.minimumHoldInterval = 0.15

        #expect(state.handle(.down) == .startRecording)
        clock = clock.addingTimeInterval(0.05)
        #expect(state.handle(.up) == .cancelRecording)
    }

    @Test func escapeCancelsWhileRecording() {
        let state = PushToTalkState()
        #expect(state.handle(.down) == .startRecording)
        #expect(state.handle(.escape) == .cancelRecording)
        #expect(state.state == .idle)
    }

    @Test func upWhileIdleIsNoop() {
        let state = PushToTalkState()
        #expect(state.handle(.up) == .none)
        #expect(state.handle(.escape) == .none)
    }

    @Test func secondDownWhileRecordingIsNoop() {
        let state = PushToTalkState()
        #expect(state.handle(.down) == .startRecording)
        #expect(state.handle(.down) == .none)
        #expect(state.state == .recording)
    }
}
