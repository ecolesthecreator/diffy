import Foundation

// MARK: - Unified Diff Parser Types

/// Represents a single hunk within a unified diff
public struct UnifiedDiffHunk: Sendable {
    /// Original file starting line number
    public let oldStart: Int
    /// Original file line count
    public let oldCount: Int
    /// New file starting line number
    public let newStart: Int
    /// New file line count
    public let newCount: Int
    /// The changes within this hunk
    public let changes: [DiffChange]

    public init(oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, changes: [DiffChange]) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.changes = changes
    }
}

/// Represents a single file's diff in a unified diff output
public struct UnifiedDiffFile: Sendable, Identifiable {
    public let id = UUID()
    /// Original file path (from "--- a/path"), nil for new files
    public let oldPath: String?
    /// New file path (from "+++ b/path"), nil for deleted files
    public let newPath: String?
    /// All hunks in this file's diff
    public let hunks: [UnifiedDiffHunk]

    /// Convenience: flattened changes across all hunks
    public var changes: [DiffChange] {
        hunks.flatMap { $0.changes }
    }

    public init(oldPath: String?, newPath: String?, hunks: [UnifiedDiffHunk]) {
        self.oldPath = oldPath
        self.newPath = newPath
        self.hunks = hunks
    }
}

// MARK: - Unified Diff Parser

/// Parser for unified diff format (git diff output)
public struct UnifiedDiffParser: Sendable {

    public init() {}

    /// Parse unified diff text into file-level diffs
    /// - Parameter diffText: The unified diff output (e.g., from `git diff`)
    /// - Returns: Array of file diffs with metadata and changes
    public func parse(_ diffText: String) -> [UnifiedDiffFile] {
        var files: [UnifiedDiffFile] = []
        var currentOldPath: String?
        var currentNewPath: String?
        var currentHunks: [UnifiedDiffHunk] = []
        var currentHunkChanges: [DiffChange] = []
        var currentHunkHeader: HunkHeader?
        var inHunk = false

        let lines = diffText.components(separatedBy: "\n")

        for line in lines {
            // File header: --- a/path or --- /dev/null
            if line.hasPrefix("--- ") {
                // Finalize previous file if any
                if currentOldPath != nil || currentNewPath != nil || !currentHunks.isEmpty {
                    finalizeHunk(&currentHunks, &currentHunkChanges, currentHunkHeader)
                    files.append(UnifiedDiffFile(oldPath: currentOldPath, newPath: currentNewPath, hunks: currentHunks))
                    currentHunks = []
                    currentHunkHeader = nil
                    inHunk = false
                }
                currentOldPath = parseFilePath(line, prefix: "--- ")
                currentNewPath = nil

            } else if line.hasPrefix("+++ ") {
                currentNewPath = parseFilePath(line, prefix: "+++ ")

            } else if line.hasPrefix("@@ ") {
                // Finalize previous hunk if any
                finalizeHunk(&currentHunks, &currentHunkChanges, currentHunkHeader)
                currentHunkHeader = parseHunkHeader(line)
                inHunk = true

            } else if inHunk {
                // We're inside a hunk - parse content lines
                if line.hasPrefix("+") {
                    let text = String(line.dropFirst())
                    currentHunkChanges.append(DiffChange(operation: .insert, text: text + "\n"))
                } else if line.hasPrefix("-") {
                    let text = String(line.dropFirst())
                    currentHunkChanges.append(DiffChange(operation: .delete, text: text + "\n"))
                } else if line.hasPrefix(" ") {
                    let text = String(line.dropFirst())
                    currentHunkChanges.append(DiffChange(operation: .equal, text: text + "\n"))
                } else if line.hasPrefix("\\") {
                    // "\ No newline at end of file" - remove trailing newline from previous change
                    handleNoNewlineMarker(&currentHunkChanges)
                }
                // Skip other lines within hunk (shouldn't happen in valid diff)
            }
            // Skip git extended headers: diff --git, index, mode, etc.
        }

        // Finalize last file
        if currentOldPath != nil || currentNewPath != nil || !currentHunks.isEmpty {
            finalizeHunk(&currentHunks, &currentHunkChanges, currentHunkHeader)
            files.append(UnifiedDiffFile(oldPath: currentOldPath, newPath: currentNewPath, hunks: currentHunks))
        }

        return files
    }

    /// Parse unified diff text into a flat array of changes
    /// - Parameter diffText: The unified diff output
    /// - Returns: Flattened array of all changes across all files
    public func parseChanges(_ diffText: String) -> [DiffChange] {
        parse(diffText).flatMap { $0.changes }
    }

    // MARK: - Private Helpers

    private struct HunkHeader {
        let oldStart: Int
        let oldCount: Int
        let newStart: Int
        let newCount: Int
    }

    private func parseFilePath(_ line: String, prefix: String) -> String? {
        var path = String(line.dropFirst(prefix.count))

        // Handle "a/path" and "b/path" git prefix convention
        if path.hasPrefix("a/") || path.hasPrefix("b/") {
            path = String(path.dropFirst(2))
        }

        // Handle /dev/null for new/deleted files
        if path == "/dev/null" {
            return nil
        }

        return path
    }

    private func parseHunkHeader(_ line: String) -> HunkHeader? {
        // Format: @@ -oldStart,oldCount +newStart,newCount @@ optional context
        // Examples: @@ -1,3 +1,4 @@  or  @@ -1 +1,2 @@  or @@ -0,0 +1 @@
        let pattern = #"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        func extractInt(_ rangeIndex: Int) -> Int? {
            let range = match.range(at: rangeIndex)
            guard range.location != NSNotFound,
                  let swiftRange = Range(range, in: line) else { return nil }
            return Int(line[swiftRange])
        }

        let oldStart = extractInt(1) ?? 1
        let oldCount = extractInt(2) ?? 1
        let newStart = extractInt(3) ?? 1
        let newCount = extractInt(4) ?? 1

        return HunkHeader(oldStart: oldStart, oldCount: oldCount, newStart: newStart, newCount: newCount)
    }

    private func finalizeHunk(_ hunks: inout [UnifiedDiffHunk], _ changes: inout [DiffChange], _ header: HunkHeader?) {
        guard let header = header, !changes.isEmpty else {
            changes = []
            return
        }

        let hunk = UnifiedDiffHunk(
            oldStart: header.oldStart,
            oldCount: header.oldCount,
            newStart: header.newStart,
            newCount: header.newCount,
            changes: changes
        )
        hunks.append(hunk)
        changes = []
    }

    private func handleNoNewlineMarker(_ changes: inout [DiffChange]) {
        guard !changes.isEmpty else { return }

        let lastChange = changes.removeLast()
        if lastChange.text.hasSuffix("\n") {
            let trimmedText = String(lastChange.text.dropLast())
            changes.append(DiffChange(operation: lastChange.operation, text: trimmedText))
        } else {
            changes.append(lastChange)
        }
    }
}
