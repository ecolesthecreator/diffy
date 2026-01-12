import SwiftUI
import DiffView

@main
struct DiffViewDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: DemoTab = .textInput

    enum DemoTab: String, CaseIterable {
        case textInput = "Text Input"
        case unifiedDiff = "Unified Diff"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Demo Mode", selection: $selectedTab) {
                ForEach(DemoTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            .padding()

            Divider()

            // Content
            switch selectedTab {
            case .textInput:
                TextInputDemoView()
            case .unifiedDiff:
                UnifiedDiffDemoView()
            }
        }
    }
}

// MARK: - Text Input Demo

struct TextInputDemoView: View {
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
                Text("Text Diff Demo")
                    .font(.title2)
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
            DiffResultSection {
                if viewMode == .inline {
                    DiffTextView(oldString: oldText, newString: newText)
                } else {
                    SideBySideDiffView(oldString: oldText, newString: newText)
                }
            }
        }
    }
}

// MARK: - Unified Diff Demo (paste git diff output)

struct UnifiedDiffDemoView: View {
    @State private var diffInput: String = sampleGitDiff
    @State private var viewMode: ViewMode = .inline
    @State private var diffFiles: [UnifiedDiffFile] = []
    @State private var selectedFileIndex: Int = 0

    enum ViewMode: String, CaseIterable {
        case inline = "Inline"
        case sideBySide = "Side-by-Side"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Unified Diff Parser")
                    .font(.title2)
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

            // Input section
            VStack(alignment: .leading, spacing: 8) {
                Text("Paste git diff output below:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $diffInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.3))
            }
            .padding(.horizontal)
            .padding(.bottom)

            Divider()

            // Parsed output
            if diffFiles.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No diff parsed yet")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                HSplitView {
                    // File list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Files (\(diffFiles.count))")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        Divider()

                        List(selection: $selectedFileIndex) {
                            ForEach(Array(diffFiles.enumerated()), id: \.offset) { index, file in
                                FileRow(file: file)
                                    .tag(index)
                            }
                        }
                        .listStyle(.plain)
                    }
                    .frame(minWidth: 200, maxWidth: 300)

                    // Diff view
                    if selectedFileIndex < diffFiles.count {
                        let file = diffFiles[selectedFileIndex]
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: fileIcon(for: file))
                                    .foregroundColor(fileColor(for: file))
                                Text(file.newPath ?? file.oldPath ?? "Unknown")
                                    .font(.headline)
                                Spacer()
                                Text("\(file.changes.filter { $0.operation == .insert }.count)+  \(file.changes.filter { $0.operation == .delete }.count)-")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()

                            Divider()

                            if viewMode == .inline {
                                DiffTextView(changes: file.changes)
                            } else {
                                SideBySideDiffView(
                                    oldString: reconstructOld(from: file.changes),
                                    newString: reconstructNew(from: file.changes)
                                )
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            parseDiff()
        }
        .onChange(of: diffInput) { _, _ in
            parseDiff()
        }
    }

    private func parseDiff() {
        let parser = UnifiedDiffParser()
        diffFiles = parser.parse(diffInput)
        selectedFileIndex = 0
    }

    private func fileIcon(for file: UnifiedDiffFile) -> String {
        if file.oldPath == nil { return "plus.circle.fill" }
        if file.newPath == nil { return "minus.circle.fill" }
        return "pencil.circle.fill"
    }

    private func fileColor(for file: UnifiedDiffFile) -> Color {
        if file.oldPath == nil { return .green }
        if file.newPath == nil { return .red }
        return .orange
    }

    private func reconstructOld(from changes: [DiffChange]) -> String {
        changes.filter { $0.operation != .insert }.map { $0.text }.joined()
    }

    private func reconstructNew(from changes: [DiffChange]) -> String {
        changes.filter { $0.operation != .delete }.map { $0.text }.joined()
    }
}

// MARK: - Sample Data

private let sampleGitDiff = """
diff --git a/Sources/App.swift b/Sources/App.swift
--- a/Sources/App.swift
+++ b/Sources/App.swift
@@ -1,8 +1,9 @@
 import Foundation
+import SwiftUI

 struct App {
-    let name: String
+    let title: String
     let version: String

-    func run() {
+    func start() {
         print("Running...")
     }
 }
diff --git a/README.md b/README.md
--- a/README.md
+++ b/README.md
@@ -1,3 +1,5 @@
 # My App

-A simple application.
+A simple application built with Swift.
+
+## Features
"""

// MARK: - Shared Components

struct FileRow: View {
    let file: UnifiedDiffFile

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(file.newPath ?? file.oldPath ?? "Unknown")
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var icon: String {
        if file.oldPath == nil { return "plus.circle.fill" }
        if file.newPath == nil { return "minus.circle.fill" }
        return "pencil.circle.fill"
    }

    private var color: Color {
        if file.oldPath == nil { return .green }
        if file.newPath == nil { return .red }
        return .orange
    }
}

struct DiffResultSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
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
            }
            .padding(.horizontal)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray.opacity(0.3))
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
#endif
