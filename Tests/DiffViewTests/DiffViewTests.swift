import Testing
@testable import DiffView

@Test func testBasicDiff() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "Hello World",
        newString: "Hello Universe"
    )

    // Should have changes
    #expect(changes.count > 0)

    // Should contain "Hello " as equal
    let hasHelloEqual = changes.contains { $0.operation == .equal && $0.text.contains("Hello") }
    #expect(hasHelloEqual)
}

@Test func testIdenticalStrings() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "Same text",
        newString: "Same text"
    )

    // Should only have equal operations
    let allEqual = changes.allSatisfy { $0.operation == .equal }
    #expect(allEqual)
}

@Test func testCompletelyDifferent() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "ABC",
        newString: "XYZ"
    )

    // Should have delete and insert operations
    let hasDelete = changes.contains { $0.operation == .delete }
    let hasInsert = changes.contains { $0.operation == .insert }

    #expect(hasDelete)
    #expect(hasInsert)
}

@Test func testEmptyStrings() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "",
        newString: ""
    )

    // Empty diff
    #expect(changes.isEmpty)
}

@Test func testInsertOnly() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "",
        newString: "New text"
    )

    // Should only have insert
    #expect(changes.count == 1)
    #expect(changes.first?.operation == .insert)
    #expect(changes.first?.text == "New text")
}

@Test func testDeleteOnly() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "Old text",
        newString: ""
    )

    // Should only have delete
    #expect(changes.count == 1)
    #expect(changes.first?.operation == .delete)
    #expect(changes.first?.text == "Old text")
}

@Test func testMultilineDiff() async throws {
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "Line 1\nLine 2\nLine 3",
        newString: "Line 1\nModified Line 2\nLine 3"
    )

    // Should have changes
    #expect(changes.count > 0)

    // Should contain modifications
    let hasModifications = changes.contains { $0.operation != .equal }
    #expect(hasModifications)
}

@Test func testDiffChangeIdentifiable() async throws {
    let change1 = DiffChange(operation: .insert, text: "test")
    let change2 = DiffChange(operation: .insert, text: "test")

    // IDs should be unique
    #expect(change1.id != change2.id)
}

@Test func testDiffOperationMapping() async throws {
    // Test that DiffOperation correctly maps from Objective-C operations
    let engine = DiffEngine()
    let changes = engine.diff(
        oldString: "A",
        newString: "B"
    )

    // Should have at least delete and insert
    let operations = Set(changes.map { $0.operation })
    #expect(operations.contains(.delete) || operations.contains(.insert))
}

@Test func testTimeout() async throws {
    let engine = DiffEngine()

    // Test that timeout can be set
    engine.timeout = 2.0
    #expect(engine.timeout == 2.0)

    // Test with default timeout (should complete quickly)
    let changes = engine.diff(
        oldString: "Short text",
        newString: "Short modified text"
    )

    #expect(changes.count > 0)
}
