import SwiftUI

/// Placeholder for the Dictionary, which lands next: a place to teach
/// Blabber names, jargon, and product names it keeps getting wrong.
struct DictionaryView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Dictionary", systemImage: "character.book.closed")
        } description: {
            Text("Teach Blabber names, jargon, and terms it keeps getting wrong, and fix recurring mistakes. Coming next.")
        }
        .navigationTitle("Dictionary")
    }
}
