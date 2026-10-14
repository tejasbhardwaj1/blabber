// A plain-executable fallback test runner.
//
// `swift test` builds successfully on this CLT-only toolchain but
// silently fails to execute the test bundle: `swiftpm-testing-helper`
// returns exit 0 even against a deliberately broken assertion, with no
// diagnostic. That's a toolchain gap (XCTest/swift-testing's execution
// path appears to depend on something Xcode-only provides), not a bug
// in the tests themselves. The Testing-based suites in Tests/
// BlabberTests remain the source of truth once a full Xcode install is
// available; this runner exercises the same logic in the meantime so
// the pure-logic layers are actually verified end to end.
@testable import BlabberCore
import Foundation

var failures = 0

func check(_ name: String, _ condition: @autoclosure () -> Bool) {
    if condition() {
        print("  ok   - \(name)")
    } else {
        print("  FAIL - \(name)")
        failures += 1
    }
}

// MARK: - PushToTalkState

print("PushToTalkState")
do {
    var clock = Date(timeIntervalSince1970: 0)
    let state = PushToTalkState(now: { clock })
    check("down starts recording", state.handle(.down) == .startRecording)
    clock = clock.addingTimeInterval(1.0)
    check("long hold finishes recording", state.handle(.up) == .finishRecording)
    check("returns to idle", state.state == .idle)
}

do {
    var clock = Date(timeIntervalSince1970: 0)
    let state = PushToTalkState(now: { clock })
    state.minimumHoldInterval = 0.15
    _ = state.handle(.down)
    clock = clock.addingTimeInterval(0.05)
    check("short tap cancels", state.handle(.up) == .cancelRecording)
}

do {
    let state = PushToTalkState()
    _ = state.handle(.down)
    check("escape cancels while recording", state.handle(.escape) == .cancelRecording)
    check("escape returns to idle", state.state == .idle)
}

do {
    let state = PushToTalkState()
    check("up while idle is noop", state.handle(.up) == .none)
    check("escape while idle is noop", state.handle(.escape) == .none)
}

do {
    let state = PushToTalkState()
    _ = state.handle(.down)
    check("second down while recording is noop", state.handle(.down) == .none)
    check("state stays recording", state.state == .recording)
}

// MARK: - RulesFormatter

print("RulesFormatter")
do {
    let formatter = RulesFormatter()
    let ctx = FormatContext()
    check(
        "strips filler words",
        formatter.apply("um so I think uh we should go", context: ctx) == "So I think we should go"
    )
    check(
        "collapses whitespace",
        formatter.apply("hello    world\n\nfoo", context: ctx) == "Hello world foo"
    )
    check(
        "trims and capitalizes first letter",
        formatter.apply("  hello there  ", context: ctx) == "Hello there"
    )
    check(
        "empty input stays empty",
        formatter.apply("", context: ctx) == ""
    )
}

print("")
if failures == 0 {
    print("All checks passed.")
    exit(0)
} else {
    print("\(failures) check(s) failed.")
    exit(1)
}
