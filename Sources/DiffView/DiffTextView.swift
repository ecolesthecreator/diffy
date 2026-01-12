import SwiftUI

// MARK: - SwiftUI Diff View Component

/// A SwiftUI view that displays a diff between two strings with color coding
public struct DiffTextView: View {
    private let changes: [DiffChange]
    private let insertColor: Color
    private let deleteColor: Color
    private let font: Font
    private let scrollAxes: Axis.Set

    /// Create a diff text view
    /// - Parameters:
    ///   - oldString: The original string
    ///   - newString: The new string
    ///   - insertColor: Color for insertions (default: green)
    ///   - deleteColor: Color for deletions (default: red)
    ///   - font: Font to use (default: system monospaced)
    public init(
        oldString: String,
        newString: String,
        insertColor: Color = .green,
        deleteColor: Color = .red,
        font: Font = .system(.body, design: .monospaced),
        scrollAxes: Axis.Set = [.horizontal, .vertical]
    ) {
        let engine = DiffEngine()
        self.changes = engine.diff(oldString: oldString, newString: newString)
        self.insertColor = insertColor
        self.deleteColor = deleteColor
        self.font = font
        self.scrollAxes = scrollAxes
    }

    /// Create a diff text view from pre-computed changes
    /// - Parameters:
    ///   - changes: Pre-computed diff changes
    ///   - insertColor: Color for insertions (default: green)
    ///   - deleteColor: Color for deletions (default: red)
    ///   - font: Font to use (default: system monospaced)
    public init(
        changes: [DiffChange],
        insertColor: Color = .green,
        deleteColor: Color = .red,
        font: Font = .system(.body, design: .monospaced),
        scrollAxes: Axis.Set = [.horizontal, .vertical]
    ) {
        self.changes = changes
        self.insertColor = insertColor
        self.deleteColor = deleteColor
        self.font = font
        self.scrollAxes = scrollAxes
    }

    public var body: some View {
        ScrollView(scrollAxes) {
            Text(attributedString)
                .font(font)
                .textSelection(.enabled)
                .padding()
        }
    }

    private var attributedString: AttributedString {
        var result = AttributedString()

        for change in changes {
            var chunk = AttributedString(change.text)

            switch change.operation {
            case .insert:
                chunk.foregroundColor = insertColor
                chunk.backgroundColor = insertColor.opacity(0.2)
            case .delete:
                chunk.foregroundColor = deleteColor
                chunk.backgroundColor = deleteColor.opacity(0.2)
                chunk.strikethroughStyle = .single
            case .equal:
                // No special formatting for unchanged text
                break
            }

            result.append(chunk)
        }

        return result
    }
}

/// Side-by-side diff view showing old and new versions
public struct SideBySideDiffView: View {
    private let changes: [DiffChange]
    private let insertColor: Color
    private let deleteColor: Color
    private let font: Font

    /// Create a side-by-side diff view
    /// - Parameters:
    ///   - oldString: The original string
    ///   - newString: The new string
    ///   - insertColor: Color for insertions (default: green)
    ///   - deleteColor: Color for deletions (default: red)
    ///   - font: Font to use (default: system monospaced)
    public init(
        oldString: String,
        newString: String,
        insertColor: Color = .green,
        deleteColor: Color = .red,
        font: Font = .system(.body, design: .monospaced)
    ) {
        let engine = DiffEngine()
        self.changes = engine.diff(oldString: oldString, newString: newString)
        self.insertColor = insertColor
        self.deleteColor = deleteColor
        self.font = font
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left side - original (deletions and equal)
            ScrollView([.horizontal, .vertical]) {
                Text(oldSideAttributedString)
                    .font(font)
                    .textSelection(.enabled)
                    .padding()
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right side - new (insertions and equal)
            ScrollView([.horizontal, .vertical]) {
                Text(newSideAttributedString)
                    .font(font)
                    .textSelection(.enabled)
                    .padding()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var oldSideAttributedString: AttributedString {
        var result = AttributedString()

        for change in changes {
            switch change.operation {
            case .delete:
                var chunk = AttributedString(change.text)
                chunk.foregroundColor = deleteColor
                chunk.backgroundColor = deleteColor.opacity(0.2)
                result.append(chunk)
            case .equal:
                result.append(AttributedString(change.text))
            case .insert:
                // Don't show insertions on the old side
                break
            }
        }

        return result
    }

    private var newSideAttributedString: AttributedString {
        var result = AttributedString()

        for change in changes {
            switch change.operation {
            case .insert:
                var chunk = AttributedString(change.text)
                chunk.foregroundColor = insertColor
                chunk.backgroundColor = insertColor.opacity(0.2)
                result.append(chunk)
            case .equal:
                result.append(AttributedString(change.text))
            case .delete:
                // Don't show deletions on the new side
                break
            }
        }

        return result
    }
}

// MARK: - Lined Diff View (with line numbers)

/// A diff view that displays line numbers alongside changes
public struct LinedDiffView: View {
    private let lines: [DiffLine]
    private let insertColor: Color
    private let deleteColor: Color
    private let font: Font
    private let lineWrapping: Bool

    /// A single line in the diff with line number info
    public struct DiffLine: Identifiable {
        public let id = UUID()
        public let oldLineNumber: Int?
        public let newLineNumber: Int?
        public let operation: DiffOperation
        public let text: String
    }

    /// Create from a UnifiedDiffFile (preserves line numbers from hunks)
    public init(
        file: UnifiedDiffFile,
        insertColor: Color = .green,
        deleteColor: Color = .red,
        font: Font = .system(.body, design: .monospaced),
        lineWrapping: Bool = false
    ) {
        self.lines = Self.buildLines(from: file)
        self.insertColor = insertColor
        self.deleteColor = deleteColor
        self.font = font
        self.lineWrapping = lineWrapping
    }

    /// Create from hunks directly
    public init(
        hunks: [UnifiedDiffHunk],
        insertColor: Color = .green,
        deleteColor: Color = .red,
        font: Font = .system(.body, design: .monospaced),
        lineWrapping: Bool = false
    ) {
        self.lines = Self.buildLines(fromHunks: hunks)
        self.insertColor = insertColor
        self.deleteColor = deleteColor
        self.font = font
        self.lineWrapping = lineWrapping
    }

    public var body: some View {
        ScrollView(lineWrapping ? [.vertical] : [.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    HStack(alignment: .top, spacing: 0) {
                        // Old line number
                        Text(line.oldLineNumber.map { String($0) } ?? "")
                            .frame(width: 50, alignment: .trailing)
                            .foregroundColor(.secondary)

                        // New line number
                        Text(line.newLineNumber.map { String($0) } ?? "")
                            .frame(width: 50, alignment: .trailing)
                            .foregroundColor(.secondary)

                        // Operation indicator
                        Text(operationSymbol(line.operation))
                            .frame(width: 20)
                            .foregroundColor(operationColor(line.operation))

                        // Content
                        if lineWrapping {
                            Text(line.text)
                                .foregroundColor(operationColor(line.operation))
                                .background(operationColor(line.operation).opacity(0.1))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(line.text)
                                .foregroundColor(operationColor(line.operation))
                                .background(operationColor(line.operation).opacity(0.1))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .font(font)
                    .background(rowBackground(line.operation))
                }
            }
            .padding()
            .textSelection(.enabled)
            .fixedSize(horizontal: !lineWrapping, vertical: false)
        }
    }

    private func operationSymbol(_ op: DiffOperation) -> String {
        switch op {
        case .insert: return "+"
        case .delete: return "-"
        case .equal: return " "
        }
    }

    private func operationColor(_ op: DiffOperation) -> Color {
        switch op {
        case .insert: return insertColor
        case .delete: return deleteColor
        case .equal: return .primary
        }
    }

    private func rowBackground(_ op: DiffOperation) -> Color {
        switch op {
        case .insert: return insertColor.opacity(0.05)
        case .delete: return deleteColor.opacity(0.05)
        case .equal: return .clear
        }
    }

    private static func buildLines(from file: UnifiedDiffFile) -> [DiffLine] {
        buildLines(fromHunks: file.hunks)
    }

    private static func buildLines(fromHunks hunks: [UnifiedDiffHunk]) -> [DiffLine] {
        var result: [DiffLine] = []

        for hunk in hunks {
            var oldLine = hunk.oldStart
            var newLine = hunk.newStart

            for change in hunk.changes {
                // Split by newlines to handle multi-line changes
                let textLines = change.text.components(separatedBy: "\n")

                for (index, text) in textLines.enumerated() {
                    // Skip empty trailing line from split
                    if index == textLines.count - 1 && text.isEmpty {
                        continue
                    }

                    switch change.operation {
                    case .equal:
                        result.append(DiffLine(
                            oldLineNumber: oldLine,
                            newLineNumber: newLine,
                            operation: .equal,
                            text: text
                        ))
                        oldLine += 1
                        newLine += 1

                    case .delete:
                        result.append(DiffLine(
                            oldLineNumber: oldLine,
                            newLineNumber: nil,
                            operation: .delete,
                            text: text
                        ))
                        oldLine += 1

                    case .insert:
                        result.append(DiffLine(
                            oldLineNumber: nil,
                            newLineNumber: newLine,
                            operation: .insert,
                            text: text
                        ))
                        newLine += 1
                    }
                }
            }
        }

        return result
    }
}

// MARK: - Preview Support

#if DEBUG
struct DiffTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Inline Diff View")
                .font(.headline)

            DiffTextView(
                oldString: "The quick brown fox jumps over the lazy dog.",
                newString: "The quick red fox leaps over the sleepy dog."
            )
            .frame(height: 100)
            .border(Color.gray)

            Divider()

            Text("Side-by-Side Diff View")
                .font(.headline)

            SideBySideDiffView(
                oldString: "Hello World\nThis is a test\nOriginal text",
                newString: "Hello Universe\nThis is a test\nModified text"
            )
            .frame(height: 200)
            .border(Color.gray)
        }
        .padding()
    }
}
#endif
