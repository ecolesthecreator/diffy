# DiffView Usage Examples

## Quick Start

### 1. Basic Inline Diff

The simplest way to display a diff:

```swift
import SwiftUI
import DiffView

struct QuickDiffView: View {
    var body: some View {
        DiffTextView(
            oldString: "Hello World",
            newString: "Hello Universe"
        )
    }
}
```

### 2. Side-by-Side Comparison

Perfect for document comparison:

```swift
SideBySideDiffView(
    oldString: originalDocument,
    newString: modifiedDocument
)
```

## Real-World Examples

### Code Review Tool

```swift
struct CodeReviewView: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack {
            Text(pullRequest.fileName)
                .font(.title2)
                .fontWeight(.bold)

            SideBySideDiffView(
                oldString: pullRequest.originalCode,
                newString: pullRequest.modifiedCode,
                font: .custom("SF Mono", size: 12)
            )
        }
    }
}
```

### Live Text Editor with Diff Preview

```swift
struct LiveDiffEditor: View {
    @State private var originalText = ""
    @State private var currentText = ""
    @State private var showDiff = false

    var body: some View {
        HSplitView {
            // Editor
            TextEditor(text: $currentText)
                .font(.system(.body, design: .monospaced))

            // Live diff preview
            if showDiff {
                DiffTextView(
                    oldString: originalText,
                    newString: currentText
                )
            }
        }
        .toolbar {
            Toggle("Show Diff", isOn: $showDiff)
        }
    }
}
```

### Document Version Comparison

```swift
struct VersionComparisonView: View {
    let versions: [DocumentVersion]
    @State private var selectedVersionA = 0
    @State private var selectedVersionB = 1

    var body: some View {
        VStack {
            // Version selectors
            HStack {
                Picker("Version A", selection: $selectedVersionA) {
                    ForEach(versions.indices, id: \.self) { index in
                        Text("v\(versions[index].number)")
                    }
                }

                Picker("Version B", selection: $selectedVersionB) {
                    ForEach(versions.indices, id: \.self) { index in
                        Text("v\(versions[index].number)")
                    }
                }
            }

            // Diff view
            SideBySideDiffView(
                oldString: versions[selectedVersionA].content,
                newString: versions[selectedVersionB].content
            )
        }
    }
}
```

### Git Commit Preview

```swift
struct CommitDiffView: View {
    let commit: GitCommit

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Commit info
                VStack(alignment: .leading) {
                    Text(commit.message)
                        .font(.title3)
                    Text(commit.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

                // File diffs
                ForEach(commit.changedFiles) { file in
                    VStack(alignment: .leading) {
                        Text(file.path)
                            .font(.headline)
                            .padding(.horizontal)

                        DiffTextView(
                            oldString: file.oldContent,
                            newString: file.newContent,
                            insertColor: .green,
                            deleteColor: .red
                        )
                        .frame(height: 300)
                    }
                }
            }
        }
    }
}
```

### Custom Styled Diff

```swift
struct CustomStyledDiffView: View {
    let before: String
    let after: String

    var body: some View {
        DiffTextView(
            oldString: before,
            newString: after,
            insertColor: .blue,           // Custom insert color
            deleteColor: .orange,         // Custom delete color
            font: .custom("Menlo", size: 14)  // Custom font
        )
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
```

### Using the Engine Directly for Processing

```swift
import DiffView

class DiffProcessor {
    let engine = DiffEngine()

    func analyzeDiff(original: String, modified: String) -> DiffStatistics {
        let changes = engine.diff(
            oldString: original,
            newString: modified
        )

        var stats = DiffStatistics()

        for change in changes {
            switch change.operation {
            case .insert:
                stats.insertions += change.text.count
                stats.insertedLines += change.text.components(separatedBy: "\n").count
            case .delete:
                stats.deletions += change.text.count
                stats.deletedLines += change.text.components(separatedBy: "\n").count
            case .equal:
                stats.unchanged += change.text.count
            }
        }

        return stats
    }

    func generateDiffReport(original: String, modified: String) -> String {
        let changes = engine.diff(oldString: original, newString: modified)
        var report = "Diff Report\n"
        report += "===========\n\n"

        for change in changes {
            let prefix: String
            switch change.operation {
            case .insert:
                prefix = "+ "
            case .delete:
                prefix = "- "
            case .equal:
                prefix = "  "
            }

            for line in change.text.components(separatedBy: "\n") {
                report += "\(prefix)\(line)\n"
            }
        }

        return report
    }
}

struct DiffStatistics {
    var insertions = 0
    var deletions = 0
    var unchanged = 0
    var insertedLines = 0
    var deletedLines = 0
}
```

### Interactive Diff Explorer

```swift
struct InteractiveDiffView: View {
    let changes: [DiffChange]
    @State private var selectedChange: DiffChange.ID?

    var body: some View {
        HSplitView {
            // List of changes
            List(changes, selection: $selectedChange) { change in
                HStack {
                    Image(systemName: iconForOperation(change.operation))
                        .foregroundColor(colorForOperation(change.operation))

                    Text(change.text.prefix(50))
                        .lineLimit(1)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .frame(width: 300)

            // Detail view
            if let selectedID = selectedChange,
               let change = changes.first(where: { $0.id == selectedID }) {
                VStack(alignment: .leading) {
                    Text("Operation: \(operationName(change.operation))")
                        .font(.headline)

                    ScrollView {
                        Text(change.text)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                }
            }
        }
    }

    func iconForOperation(_ op: DiffOperation) -> String {
        switch op {
        case .insert: return "plus.circle.fill"
        case .delete: return "minus.circle.fill"
        case .equal: return "equal.circle"
        }
    }

    func colorForOperation(_ op: DiffOperation) -> Color {
        switch op {
        case .insert: return .green
        case .delete: return .red
        case .equal: return .gray
        }
    }

    func operationName(_ op: DiffOperation) -> String {
        switch op {
        case .insert: return "Insertion"
        case .delete: return "Deletion"
        case .equal: return "Unchanged"
        }
    }
}
```

## Platform-Specific Features

### iOS: Pull to Refresh Diff

```swift
#if os(iOS)
struct PullToRefreshDiffView: View {
    @State private var oldText = ""
    @State private var newText = ""

    var body: some View {
        NavigationView {
            DiffTextView(
                oldString: oldText,
                newString: newText
            )
            .navigationTitle("Document Diff")
            .refreshable {
                await loadLatestVersions()
            }
        }
    }

    func loadLatestVersions() async {
        // Load data...
    }
}
#endif
```

### macOS: Window Toolbar Integration

```swift
#if os(macOS)
struct MacOSDiffWindow: View {
    @State private var viewMode: ViewMode = .inline

    enum ViewMode {
        case inline, sideBySide
    }

    var body: some View {
        Group {
            if viewMode == .inline {
                DiffTextView(oldString: old, newString: new)
            } else {
                SideBySideDiffView(oldString: old, newString: new)
            }
        }
        .toolbar {
            ToolbarItem {
                Picker("View", selection: $viewMode) {
                    Label("Inline", systemImage: "doc.text")
                        .tag(ViewMode.inline)
                    Label("Side by Side", systemImage: "square.split.2x1")
                        .tag(ViewMode.sideBySide)
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
#endif
```

## Tips and Best Practices

1. **Performance**: For very large files, consider setting a timeout:
   ```swift
   let engine = DiffEngine()
   engine.timeout = 5.0  // 5 seconds max
   ```

2. **Memory**: Process diffs in chunks for large files:
   ```swift
   let chunkSize = 10000
   let chunks = largeText.chunked(by: chunkSize)
   for chunk in chunks {
       let diff = engine.diff(oldString: chunk.old, newString: chunk.new)
       // Process chunk...
   }
   ```

3. **UI Responsiveness**: Compute diffs on background thread:
   ```swift
   Task {
       let changes = await Task.detached {
           engine.diff(oldString: old, newString: new)
       }.value
       // Update UI with changes
   }
   ```

4. **Custom Colors**: Match your app's theme:
   ```swift
   DiffTextView(
       oldString: old,
       newString: new,
       insertColor: Color(hex: "#4CAF50"),  // Your brand color
       deleteColor: Color(hex: "#F44336")   // Your brand color
   )
   ```
