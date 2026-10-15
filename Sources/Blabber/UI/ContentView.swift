import SwiftUI

/// The main window: a standard `NavigationSplitView` with a two-item
/// sidebar (History, Dictionary).
struct ContentView: View {
    let appDelegate: AppDelegate

    @Environment(\.openWindow) private var openWindow
    @State private var selection: SidebarItem = .history

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
            .navigationTitle("Blabber")
        } detail: {
            switch selection {
            case .history:
                HistoryView(model: appDelegate.model)
            case .dictionary:
                DictionaryView()
            }
        }
        .onAppear {
            // Route the menu bar's "Open Blabber" item through SwiftUI's
            // own window machinery, so it reliably recreates the window
            // even after it's been fully closed.
            appDelegate.openMainWindowAction = { openWindow(id: "main") }
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case history
    case dictionary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .history: return "History"
        case .dictionary: return "Dictionary"
        }
    }

    var symbol: String {
        switch self {
        case .history: return "waveform"
        case .dictionary: return "character.book.closed"
        }
    }
}
