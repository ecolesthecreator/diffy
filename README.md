# DiffView

A cross-platform Swift package for displaying text diffs in iOS and macOS applications using SwiftUI.

## Features

- 📱 **Cross-Platform**: Works on both iOS 15+ and macOS 12+
- 🎨 **SwiftUI Native**: Built with SwiftUI for modern, declarative UI
- 🔄 **Multiple View Modes**: Inline and side-by-side diff views
- ⚡️ **Powered by Google's diff-match-patch**: Uses battle-tested diff algorithm
- 🎯 **Simple API**: Easy-to-use Swift API wrapping Objective-C implementation
- 🎭 **Customizable**: Configure colors, fonts, and appearance

## Installation

### Swift Package Manager

Add DiffView to your project via Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ecolesthecreator/diffy.git", branch: "main")
]
```

## Usage

### Basic Inline Diff View

```swift
import SwiftUI
import DiffView

struct MyView: View {
    var body: some View {
        DiffTextView(
            oldString: "The quick brown fox",
            newString: "The quick red fox"
        )
    }
}
```

### Side-by-Side Diff View

```swift
SideBySideDiffView(
    oldString: "Original text",
    newString: "Modified text"
)
```

### Custom Colors and Fonts

```swift
DiffTextView(
    oldString: oldText,
    newString: newText,
    insertColor: .blue,      // Custom color for insertions
    deleteColor: .orange,    // Custom color for deletions
    font: .custom("Menlo", size: 14)
)
```

### Using the Diff Engine Directly

```swift
import DiffView

let engine = DiffEngine()
let changes = engine.diff(
    oldString: "Hello World",
    newString: "Hello Universe"
)

// Process changes manually
for change in changes {
    switch change.operation {
    case .insert:
        print("+ \(change.text)")
    case .delete:
        print("- \(change.text)")
    case .equal:
        print("  \(change.text)")
    }
}
```

## API Reference

### `DiffTextView`

A SwiftUI view displaying an inline diff with color-coded changes.

**Parameters:**
- `oldString: String` - The original text
- `newString: String` - The modified text
- `insertColor: Color` - Color for inserted text (default: green)
- `deleteColor: Color` - Color for deleted text (default: red)
- `font: Font` - Font to use (default: system monospaced)

### `SideBySideDiffView`

A SwiftUI view displaying old and new versions side-by-side.

**Parameters:**
- Same as `DiffTextView`

### `DiffEngine`

The core diff computation engine.

**Methods:**
- `diff(oldString:newString:cleanup:) -> [DiffChange]` - Compute differences between two strings

### `DiffChange`

Represents a single change in a diff.

**Properties:**
- `id: UUID` - Unique identifier
- `operation: DiffOperation` - The type of change (.insert, .delete, .equal)
- `text: String` - The text content

## Demo App

Run the included demo app to see DiffView in action:

```bash
cd DemoApp
swift run
```

Or open `DemoApp` folder in Xcode to run on iOS Simulator or macOS.

## Platform Support

- **iOS**: 15.0+
- **macOS**: 12.0+
- **Swift**: 5.9+

## How It Works

DiffView uses Google's [diff-match-patch](https://github.com/google/diff-match-patch) library, which implements:

- **Myers' diff algorithm** for efficient difference computation
- **Semantic cleanup** for human-readable diffs
- **Line and character-level diffing**

The package wraps the Objective-C implementation with a modern, Swift-friendly API and provides SwiftUI views for easy integration.

## Performance

The diff algorithm is highly optimized and can handle:
- Large text files (thousands of lines)
- Real-time diff computation as users type
- Configurable timeout for very long texts

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE). Diffs are computed with Google's diff-match-patch, also Apache 2.0.

## Credits

- **Google diff-match-patch**: The core diff algorithm
- **Pasi Salenius**: Swift Package Manager wrapper for diff-match-patch

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Examples

### Multiline Text Diff

```swift
let before = """
function hello() {
    console.log('Hello World');
}
"""

let after = """
function greet(name) {
    console.log('Hello ' + name);
}
"""

DiffTextView(oldString: before, newString: after)
```

### Using in Forms

```swift
struct DocumentCompareView: View {
    @State var oldDoc: String
    @State var newDoc: String

    var body: some View {
        VStack {
            Text("Document Comparison")
                .font(.title)

            SideBySideDiffView(
                oldString: oldDoc,
                newString: newDoc
            )
        }
    }
}
```

## FAQ

**Q: Can I use this for code diffing?**
A: Yes! The monospaced font makes it perfect for code. The algorithm works on any plain text.

**Q: Does it support syntax highlighting?**
A: Not built-in, but you can extend the views to add syntax highlighting on top of the diff coloring.

**Q: Can I customize the colors?**
A: Yes, both views accept `insertColor` and `deleteColor` parameters.

**Q: Is it performant for large files?**
A: Yes, but you can set a timeout via `DiffEngine.timeout` for very large texts.
