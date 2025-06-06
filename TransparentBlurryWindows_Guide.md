# Creating Fully Transparent Blurry Windows in SwiftUI/macOS

This guide demonstrates how to create beautiful, fully transparent blurry windows in a SwiftUI macOS application, based on the FloatingNotes app implementation.

## Overview

The FloatingNotes app creates floating, semi-transparent windows with a blur effect that integrates beautifully with the macOS desktop. Here's how it's implemented:

## Key Components

### 1. Window Configuration

The core window configuration is done in the `WindowManager` class. Here's how to set up a transparent, blurry window:

```swift
// WindowManager.swift - Creating a new transparent window
func addNewNoteWindow() {
    let newWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    
    // Configure frame with random offset for multiple windows
    if let screen = NSScreen.main {
        let screenRect = screen.visibleFrame
        let xOffset = CGFloat.random(in: -40...40)
        let yOffset = CGFloat.random(in: -40...40)
        let newOriginX = (screenRect.width - newWindow.frame.width) / 2 + xOffset
        let newOriginY = (screenRect.height - newWindow.frame.height) / 2 + yOffset
        newWindow.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
    }

    // Apply all styling for transparency and blur
    newWindow.titlebarAppearsTransparent = true
    newWindow.styleMask.insert(.fullSizeContentView)
    newWindow.isOpaque = false
    newWindow.backgroundColor = .clear
    newWindow.level = .floating // Make the window float above others
    newWindow.collectionBehavior = .canJoinAllSpaces // Show on all spaces
    
    // Create and set the content view
    let noteView = NoteView(window: newWindow)
    newWindow.contentView = NSHostingView(rootView: noteView)
    newWindow.delegate = self
    
    openWindows.append(newWindow)
    newWindow.makeKeyAndOrderFront(nil)
}
```

### 2. Visual Effect View

The blur effect is achieved using `NSVisualEffectView` wrapped in a SwiftUI `NSViewRepresentable`:

```swift
// ContentView.swift - NSViewRepresentable wrapper for NSVisualEffectView
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .dark
        return visualEffect
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}
```

### 3. Content View Implementation

The `NoteView` combines the visual effect with transparent content:

```swift
// ContentView.swift - NoteView body
var body: some View {
    ZStack {
        // Background visual effect
        VisualEffectView()
            .ignoresSafeArea()
        
        // Use TextEditor for a multi-line editable text area
        TextEditor(text: $noteText)
            .scrollContentBackground(.hidden) // Hide the default background
            .background(.clear) // Make TextEditor background transparent
            .font(.system(size: 14))
            .foregroundColor(.primary) // Ensure text is visible
            .scrollIndicators(.never)
            .padding(.leading, 10)
    }
    .focusable()
    .focused($isFocused)
    // ... additional modifiers
}
```

## Key Properties Explained

### Window Transparency Properties

1. **`titlebarAppearsTransparent`**: Makes the title bar transparent
2. **`styleMask.insert(.fullSizeContentView)`**: Extends content under the title bar
3. **`isOpaque = false`**: Makes the window non-opaque
4. **`backgroundColor = .clear`**: Sets window background to clear

### Window Behavior Properties

1. **`level = .floating`**: Makes window float above other windows
2. **`collectionBehavior = .canJoinAllSpaces`**: Shows window on all desktop spaces

### Visual Effect Properties

1. **`blendingMode = .behindWindow`**: Blends with content behind the window
2. **`state = .active`**: Keeps the effect always active
3. **`material = .dark`**: Uses dark material for the blur effect

## Settings Window Implementation

The app also applies the same styling to its settings window:

```swift
// FloatingNotesApp.swift - Settings window styling
Settings {
    SettingsView()
        .onAppear {
            for window in NSApplication.shared.windows {
                if let contentView = window.contentView,
                   contentView.subviews.contains(where: { ($0 as? NSHostingView<SettingsView>) != nil }) || window.title == "Floating Notes Settings" {
                    window.titlebarAppearsTransparent = true
                    window.styleMask.insert(.fullSizeContentView)
                    window.isOpaque = false
                    window.backgroundColor = .clear
                    window.level = .floating
                    window.collectionBehavior = .canJoinAllSpaces
                    break
                }
            }
        }
}
```

## Content Transparency

To ensure the content within the window is also transparent:

1. **TextEditor**: Use `.scrollContentBackground(.hidden)` and `.background(.clear)`
2. **Other Views**: Apply `.background(.clear)` to maintain transparency
3. **ZStack**: Use `VisualEffectView` as the bottom layer

## App Entitlements

For proper sandboxing while maintaining functionality:

```xml
<!-- FloatingNotes.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

## Window Management

The `WindowManager` singleton handles multiple windows:

```swift
class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()
    private var openWindows: [NSWindow] = []
    
    // NSWindowDelegate method to handle window closing
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            openWindows.removeAll { $0 == window }
            print("WindowManager: Window closed. Total managed windows: \(openWindows.count)")
        }
    }
}
```

## Material Options

You can customize the blur effect by changing the material:

- `.dark` - Dark blur effect
- `.light` - Light blur effect  
- `.ultraThin` - Very subtle blur
- `.thin` - Light blur
- `.regular` - Standard blur
- `.thick` - Heavy blur
- `.hudWindow` - HUD-style blur

## Best Practices

1. **Memory Management**: Always maintain proper references to windows
2. **Window Delegation**: Implement `NSWindowDelegate` for cleanup
3. **Focus Management**: Use `@FocusState` for proper keyboard handling
4. **Background Transparency**: Ensure all content views use clear backgrounds
5. **Testing**: Test on different desktop backgrounds to ensure readability

## Troubleshooting

### Common Issues:

1. **Window not transparent**: Ensure `isOpaque = false` and `backgroundColor = .clear`
2. **Content not blurred**: Check that `VisualEffectView` is in the background layer
3. **Text not visible**: Adjust `foregroundColor` or try different blur materials
4. **Window not floating**: Verify `level = .floating` is set

This implementation creates beautiful, functional transparent blurry windows that integrate seamlessly with the macOS desktop environment. 