import SwiftUI
import DiffView

@main
struct DiffViewDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}

struct ContentView: View {
    @State private var oldText = """
    The quick brown fox jumps over the lazy dog.
    This is the original text.
    It has multiple lines.
    Some text will be changed.
    Some will be deleted.
    """

    @State private var newText = """
    The quick red fox leaps over the sleepy dog.
    This is the modified text.
    It has multiple lines.
    Some text will be changed.
    And some new lines added.
    """

    @State private var viewMode: ViewMode = .inline

    enum ViewMode: String, CaseIterable {
        case inline = "Inline"
        case sideBySide = "Side-by-Side"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("DiffView Demo")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding()

            Divider()

            // Input section
            VStack(spacing: 10) {
                Text("Edit the text below to see the diff update in real-time")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    VStack(alignment: .leading) {
                        Text("Original Text")
                            .font(.headline)
                        TextEditor(text: $oldText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100)
                            .border(Color.gray.opacity(0.3))
                    }

                    VStack(alignment: .leading) {
                        Text("Modified Text")
                            .font(.headline)
                        TextEditor(text: $newText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100)
                            .border(Color.gray.opacity(0.3))
                    }
                }
            }
            .padding()

            Divider()

            // Diff view section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Diff Result")
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 10) {
                        Label("Deleted", systemImage: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)

                        Label("Inserted", systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    .font(.caption)
                }
                .padding(.horizontal)

                Group {
                    if viewMode == .inline {
                        DiffTextView(
                            oldString: oldText,
                            newString: newText
                        )
                    } else {
                        SideBySideDiffView(
                            oldString: oldText,
                            newString: newText
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray.opacity(0.3))
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
#endif
