# Getting Started with DiffView

## What You Have

A complete, production-ready Swift package for displaying text diffs on iOS and macOS!

## Project Structure

```
diffy/
├── Package.swift                 # Main package manifest
├── README.md                     # Full documentation
├── USAGE_EXAMPLES.md            # Real-world code examples
├── GETTING_STARTED.md           # This file
│
├── Sources/DiffView/
│   ├── DiffView.swift           # Core API (DiffEngine, DiffChange, etc.)
│   └── DiffTextView.swift       # SwiftUI components
│
├── Tests/DiffViewTests/
│   └── DiffViewTests.swift      # 10 passing unit tests
│
└── DemoApp/                     # Full demo application
    ├── Package.swift
    └── Sources/DiffViewDemo/
        └── DemoApp.swift        # Interactive demo with live editing
```

## Quick Start (3 Minutes)

### 1. Run the Demo App

```bash
cd DemoApp
swift run
```

This opens an interactive demo where you can:
- Edit text in real-time
- See diffs update instantly
- Switch between inline and side-by-side views
- Test with your own text

### 2. Use in Your Xcode Project

#### Option A: Local Package
1. In Xcode: File → Add Package Dependencies
2. Click "Add Local..."
3. Select the `diffy` folder
4. Add to your target

#### Option B: As a Dependency
Add to your `Package.swift`:
```swift
dependencies: [
    .package(path: "../path/to/diffy")
]
```

### 3. Write Your First Diff View

```swift
import SwiftUI
import DiffView

struct MyDiffView: View {
    var body: some View {
        DiffTextView(
            oldString: "Hello World",
            newString: "Hello Universe"
        )
    }
}
```

That's it! 🎉

## Running Tests

```bash
swift test
```

All 10 tests should pass, covering:
- Basic diff operations
- Edge cases (empty strings, identical strings)
- Multiline text
- Insert/delete/equal operations
- Timeout configuration

## Key Features

### Two View Modes

**Inline View** - Traditional git-style diff:
```swift
DiffTextView(oldString: before, newString: after)
```

**Side-by-Side View** - Compare documents side by side:
```swift
SideBySideDiffView(oldString: before, newString: after)
```

### Customization

```swift
DiffTextView(
    oldString: old,
    newString: new,
    insertColor: .blue,      // Custom colors
    deleteColor: .orange,
    font: .custom("Menlo", size: 14)  // Custom font
)
```

### Direct Engine Access

```swift
let engine = DiffEngine()
let changes = engine.diff(
    oldString: "original",
    newString: "modified"
)

// Process changes manually
for change in changes {
    print("\(change.operation): \(change.text)")
}
```

## Platform Support

- ✅ iOS 15.0+
- ✅ macOS 12.0+
- ✅ Swift 5.9+
- ✅ SwiftUI
- ✅ Xcode 15+

## Next Steps

1. **Try the Demo**: Run `cd DemoApp && swift run`
2. **Read Examples**: Check out `USAGE_EXAMPLES.md` for real-world patterns
3. **Integrate**: Add to your project and customize
4. **Explore API**: See `README.md` for full API documentation

## Common Use Cases

- **Code Review Tools**: Show PR diffs
- **Document Comparison**: Version control for documents
- **Git Clients**: Display commit changes
- **Text Editors**: Live diff preview
- **Merge Tools**: Conflict resolution
- **Backup Tools**: Show what changed

## How to Test Locally

### Test the Package

```bash
# Run tests
swift test

# Build the package
swift build

# Build for release
swift build -c release
```

### Test the Demo App

```bash
cd DemoApp

# Run on macOS
swift run

# Build and test
swift build
swift test
```

### Test in Xcode

1. Open `Package.swift` in Xcode
2. Select the scheme (DiffView or DiffViewDemo)
3. Build and run (⌘R)
4. Run tests (⌘U)

## Architecture Overview

```
┌─────────────────────────────────────┐
│         Your SwiftUI App            │
└─────────────────┬───────────────────┘
                  │
        ┌─────────▼──────────┐
        │  DiffTextView      │  SwiftUI Components
        │  SideBySideDiffView│
        └─────────┬──────────┘
                  │
        ┌─────────▼──────────┐
        │  DiffEngine        │  Swift API Layer
        │  DiffChange        │
        │  DiffOperation     │
        └─────────┬──────────┘
                  │
        ┌─────────▼──────────┐
        │  diff-match-patch  │  Objective-C (Google)
        │  (via SPM)         │
        └────────────────────┘
```

## Troubleshooting

### Build Issues

**Problem**: "Cannot find 'DiffView' in scope"
**Solution**: Make sure package is added to target dependencies

**Problem**: "Module 'diff_match_patch' not found"
**Solution**: Run `swift package resolve` to fetch dependencies

### Runtime Issues

**Problem**: Diff takes too long
**Solution**: Set a timeout:
```swift
let engine = DiffEngine()
engine.timeout = 2.0  // seconds
```

**Problem**: Memory issues with large files
**Solution**: Process in chunks or use streaming

## Performance Tips

1. **Large Files**: Set timeout to prevent hanging
2. **Real-time Updates**: Debounce user input
3. **Many Diffs**: Reuse DiffEngine instance
4. **Background Processing**: Compute on background thread

Example for real-time diff:
```swift
@State private var text = ""
@State private var debouncedText = ""

var body: some View {
    TextEditor(text: $text)
        .onChange(of: text) { oldValue, newValue in
            // Debounce for performance
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                debouncedText = newValue
            }
        }

    DiffTextView(
        oldString: originalText,
        newString: debouncedText
    )
}
```

## Resources

- **README.md**: Complete API documentation
- **USAGE_EXAMPLES.md**: 10+ real-world examples
- **DemoApp**: Interactive demo application
- **Tests**: 10 unit tests showing usage patterns
- **Google diff-match-patch**: [Original library docs](https://github.com/google/diff-match-patch)

## Contributing

Found a bug or want to add a feature?

1. Check the existing code
2. Write tests
3. Update documentation
4. Submit changes

## What Makes This Special

✨ **Pure SwiftUI** - No UIKit/AppKit required
🎯 **Simple API** - Intuitive Swift interface
🔄 **Cross-Platform** - One codebase for iOS & macOS
⚡️ **Battle-Tested** - Google's proven algorithm
📦 **Zero Config** - Works out of the box
🎨 **Customizable** - Colors, fonts, styling
📱 **Modern** - Swift 5.9, SwiftUI, iOS 15+

Enjoy building with DiffView! 🚀
