import Testing
@testable import BlabberCore

@Suite struct RulesFormatterTests {
    let formatter = RulesFormatter()
    let ctx = FormatContext()

    @Test func stripsFillerWords() {
        let result = formatter.apply("um so I think uh we should go", context: ctx)
        #expect(result == "So I think we should go")
    }

    @Test func collapsesWhitespace() {
        let result = formatter.apply("hello    world\n\nfoo", context: ctx)
        #expect(result == "Hello world foo")
    }

    @Test func trimsAndCapitalizesFirstLetter() {
        let result = formatter.apply("  hello there  ", context: ctx)
        #expect(result == "Hello there")
    }

    @Test func emptyInputStaysEmpty() {
        let result = formatter.apply("", context: ctx)
        #expect(result == "")
    }
}
