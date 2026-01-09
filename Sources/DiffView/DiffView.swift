import Foundation
import diff_match_patch

// MARK: - Swift-Friendly Diff API

/// Represents the type of operation in a diff
public enum DiffOperation: Sendable {
    case insert
    case delete
    case equal

    init(from objcOperation: diff_match_patch.Operation) {
        switch objcOperation {
        case DIFF_INSERT:
            self = .insert
        case DIFF_DELETE:
            self = .delete
        case DIFF_EQUAL:
            self = .equal
        default:
            self = .equal
        }
    }
}

/// Represents a single change in a diff
public struct DiffChange: Sendable, Identifiable {
    public let id = UUID()
    public let operation: DiffOperation
    public let text: String

    public init(operation: DiffOperation, text: String) {
        self.operation = operation
        self.text = text
    }

    init(from objcDiff: Diff) {
        self.operation = DiffOperation(from: objcDiff.operation)
        self.text = objcDiff.text
    }
}

/// Main engine for computing diffs between two strings
public class DiffEngine {
    private let engine = DiffMatchPatch()

    /// Timeout for diff computation (0 = no timeout)
    public var timeout: TimeInterval {
        get { engine.diff_Timeout }
        set { engine.diff_Timeout = newValue }
    }

    public init() {}

    /// Compute the diff between two strings
    /// - Parameters:
    ///   - oldString: The original string
    ///   - newString: The new string
    ///   - cleanup: Whether to perform semantic cleanup (default: true)
    /// - Returns: Array of DiffChange objects representing the differences
    public func diff(oldString: String, newString: String, cleanup: Bool = true) -> [DiffChange] {
        let diffs = engine.diff_main(ofOldString: oldString, andNewString: newString)

        if cleanup {
            engine.diff_cleanupSemantic(diffs)
        }

        guard let diffArray = diffs as? [Diff] else {
            return []
        }

        return diffArray.map { DiffChange(from: $0) }
    }

    /// Generate HTML representation of the diff
    /// - Parameter changes: Array of DiffChange objects
    /// - Returns: HTML string
    public func prettyHtml(changes: [DiffChange]) -> String {
        // Convert back to Objective-C format for HTML generation
        let diffs = NSMutableArray()
        for change in changes {
            let operation: diff_match_patch.Operation
            switch change.operation {
            case .insert: operation = DIFF_INSERT
            case .delete: operation = DIFF_DELETE
            case .equal: operation = DIFF_EQUAL
            }
            if let diff = Diff(operation: operation, andText: change.text) {
                diffs.add(diff)
            }
        }
        return engine.diff_prettyHtml(diffs)
    }
}
