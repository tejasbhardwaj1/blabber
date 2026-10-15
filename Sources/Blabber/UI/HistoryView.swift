import AppKit
import SwiftUI

/// History pane: the recorder on top, the searchable list of past
/// dictations below.
struct HistoryView: View {
    @Bindable var model: AppModel
    @State private var query = ""

    private var filtered: [TranscriptionRecord] {
        guard !query.isEmpty else { return model.records }
        return model.records.filter {
            $0.text.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            RecorderView(model: model)
            Divider()
            listContent
        }
        .navigationTitle("History")
        .searchable(text: $query, placement: .toolbar, prompt: "Search transcriptions")
    }

    @ViewBuilder
    private var listContent: some View {
        if model.records.isEmpty {
            ContentUnavailableView {
                Label("No transcriptions yet", systemImage: "waveform")
            } description: {
                Text("Hold Right ⌘ anywhere, or press Start, to dictate. What you say shows up here.")
            }
        } else if filtered.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(filtered) { record in
                HistoryRow(record: record)
            }
            .listStyle(.inset)
        }
    }
}

private struct HistoryRow: View {
    let record: TranscriptionRecord
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(record.text)
                    .font(.body)
                    .textSelection(.enabled)
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                copy()
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .help("Copy transcription")
            .accessibilityLabel(copied ? "Copied" : "Copy transcription")
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(record.text, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            copied = false
        }
    }
}
