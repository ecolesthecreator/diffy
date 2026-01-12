import Testing
import Foundation
@testable import DiffView

// MARK: - Basic Parsing Tests

@Test func testParseSimpleHunk() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1,4 +1,5 @@
     unchanged line
    -deleted line
    +inserted line
    +another new line
     more unchanged
    """

    let parser = UnifiedDiffParser()
    let changes = parser.parseChanges(diff)

    #expect(changes.count == 5)
    #expect(changes[0].operation == .equal)
    #expect(changes[0].text == "unchanged line\n")
    #expect(changes[1].operation == .delete)
    #expect(changes[1].text == "deleted line\n")
    #expect(changes[2].operation == .insert)
    #expect(changes[2].text == "inserted line\n")
    #expect(changes[3].operation == .insert)
    #expect(changes[3].text == "another new line\n")
    #expect(changes[4].operation == .equal)
    #expect(changes[4].text == "more unchanged\n")
}

@Test func testParseMultipleHunks() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1,2 +1,2 @@
     line 1
    -old line 2
    +new line 2
    @@ -10,2 +10,2 @@
     line 10
    -old line 11
    +new line 11
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 1)
    #expect(files[0].hunks.count == 2)
    #expect(files[0].hunks[0].oldStart == 1)
    #expect(files[0].hunks[1].oldStart == 10)
}

@Test func testParseMultipleFiles() {
    let diff = """
    --- a/file1.txt
    +++ b/file1.txt
    @@ -1 +1 @@
    -old
    +new
    --- a/file2.txt
    +++ b/file2.txt
    @@ -1 +1 @@
    -foo
    +bar
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 2)
    #expect(files[0].newPath == "file1.txt")
    #expect(files[1].newPath == "file2.txt")
}

@Test func testFilePaths() {
    let diff = """
    --- a/src/components/Button.swift
    +++ b/src/components/Button.swift
    @@ -1 +1 @@
    -old
    +new
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 1)
    #expect(files[0].oldPath == "src/components/Button.swift")
    #expect(files[0].newPath == "src/components/Button.swift")
}

// MARK: - Edge Case Tests

@Test func testNewFile() {
    let diff = """
    --- /dev/null
    +++ b/newfile.txt
    @@ -0,0 +1,2 @@
    +line 1
    +line 2
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 1)
    #expect(files[0].oldPath == nil)
    #expect(files[0].newPath == "newfile.txt")
    #expect(files[0].changes.allSatisfy { $0.operation == .insert })
}

@Test func testDeletedFile() {
    let diff = """
    --- a/deleted.txt
    +++ /dev/null
    @@ -1,2 +0,0 @@
    -line 1
    -line 2
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 1)
    #expect(files[0].oldPath == "deleted.txt")
    #expect(files[0].newPath == nil)
    #expect(files[0].changes.allSatisfy { $0.operation == .delete })
}

@Test func testNoNewlineAtEndOfFile() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1 +1 @@
    -old content
    \\ No newline at end of file
    +new content
    \\ No newline at end of file
    """

    let parser = UnifiedDiffParser()
    let changes = parser.parseChanges(diff)

    // Should NOT have trailing newlines
    let deleteChange = changes.first { $0.operation == .delete }
    let insertChange = changes.first { $0.operation == .insert }

    #expect(deleteChange?.text == "old content")
    #expect(insertChange?.text == "new content")
}

@Test func testEmptyDiff() {
    let parser = UnifiedDiffParser()
    let changes = parser.parseChanges("")

    #expect(changes.isEmpty)
}

@Test func testHunkHeaderVariations() {
    // Test @@ -1 +1 @@ (no counts, defaults to 1)
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1 +1 @@
    -old
    +new
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files[0].hunks[0].oldCount == 1)
    #expect(files[0].hunks[0].newCount == 1)
}

@Test func testGitExtendedHeaders() {
    let diff = """
    diff --git a/file.txt b/file.txt
    index abc123..def456 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1 +1 @@
    -old
    +new
    """

    let parser = UnifiedDiffParser()
    let changes = parser.parseChanges(diff)

    // Should skip git headers and parse content correctly
    #expect(changes.count == 2)
    #expect(changes[0].operation == .delete)
    #expect(changes[1].operation == .insert)
}

@Test func testContextOnlyHunk() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1,3 +1,3 @@
     line 1
     line 2
     line 3
    """

    let parser = UnifiedDiffParser()
    let changes = parser.parseChanges(diff)

    #expect(changes.count == 3)
    #expect(changes.allSatisfy { $0.operation == .equal })
}

@Test func testTabsAndSpecialCharacters() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1 +1 @@
    -\told content\twith\ttabs
    +\tnew content\twith\ttabs
    """

    let parser = UnifiedDiffParser()
    let changes = parser.parseChanges(diff)

    #expect(changes[0].text.contains("\t"))
    #expect(changes[1].text.contains("\t"))
}

@Test func testHunkMetadata() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -10,5 +12,7 @@
     context
    -deleted
    +inserted
     more context
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)
    let hunk = files[0].hunks[0]

    #expect(hunk.oldStart == 10)
    #expect(hunk.oldCount == 5)
    #expect(hunk.newStart == 12)
    #expect(hunk.newCount == 7)
}

// MARK: - Integration Tests

@Test func testFlattenedChangesProperty() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1,2 +1,2 @@
     same
    -old
    +new
    @@ -10,1 +10,1 @@
    -another old
    +another new
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    // file.changes should flatten all hunks
    #expect(files[0].hunks.count == 2)
    #expect(files[0].changes.count == 5)
}

@Test func testUnifiedDiffFileIdentifiable() {
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1 +1 @@
    -old
    +new
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    // Should have unique IDs
    #expect(files[0].id != UUID())
}

// MARK: - Sendable Conformance Tests

@Test func testSendableConformance() async {
    let parser = UnifiedDiffParser()
    let diff = """
    --- a/file.txt
    +++ b/file.txt
    @@ -1 +1 @@
    -old
    +new
    """

    // Parse on background thread
    let files = await Task.detached {
        parser.parse(diff)
    }.value

    #expect(files.count == 1)
}

// MARK: - Real-World Examples

@Test func testRealWorldGitDiff() {
    // Simulating actual git diff output
    let diff = """
    diff --git a/Package.swift b/Package.swift
    index 1234567..abcdefg 100644
    --- a/Package.swift
    +++ b/Package.swift
    @@ -1,6 +1,7 @@
     // swift-tools-version: 5.9
     import PackageDescription

    +import Foundation
     let package = Package(
         name: "MyPackage",
    -    platforms: [.iOS(.v15)]
    +    platforms: [.iOS(.v16), .macOS(.v13)]
     )
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 1)
    #expect(files[0].newPath == "Package.swift")

    let changes = files[0].changes
    let inserts = changes.filter { $0.operation == .insert }
    let deletes = changes.filter { $0.operation == .delete }
    let equals = changes.filter { $0.operation == .equal }

    #expect(inserts.count == 2)
    #expect(deletes.count == 1)
    #expect(equals.count == 5)  // includes empty line after "import PackageDescription"
}

@Test func testMultiFileRealWorldDiff() {
    let diff = """
    diff --git a/Sources/Foo.swift b/Sources/Foo.swift
    --- a/Sources/Foo.swift
    +++ b/Sources/Foo.swift
    @@ -1,3 +1,3 @@
     struct Foo {
    -    var name: String
    +    var title: String
     }
    diff --git a/Tests/FooTests.swift b/Tests/FooTests.swift
    --- a/Tests/FooTests.swift
    +++ b/Tests/FooTests.swift
    @@ -5,3 +5,3 @@
     func testFoo() {
    -    let foo = Foo(name: "test")
    +    let foo = Foo(title: "test")
     }
    """

    let parser = UnifiedDiffParser()
    let files = parser.parse(diff)

    #expect(files.count == 2)
    #expect(files[0].newPath == "Sources/Foo.swift")
    #expect(files[1].newPath == "Tests/FooTests.swift")
}
