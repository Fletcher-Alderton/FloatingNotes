# Setting Focus to Windows on Appearance in SwiftUI/macOS

This guide demonstrates how to properly set focus to windows as soon as they appear in a SwiftUI macOS application, based on the FloatingNotes app implementation.

## Overview

Focus management is crucial for a good user experience. When a new window appears, users expect to be able to start typing immediately without clicking first. The FloatingNotes app implements a comprehensive focus system using both AppKit window methods and SwiftUI's `@FocusState`.

## Key Components

### 1. Window-Level Focus with `makeKeyAndOrderFront`

The primary method for giving a window focus at the AppKit level is `makeKeyAndOrderFront(_:)`. This makes the window the key window (receives keyboard input) and brings it to the front.

```swift
// WindowManager.swift - Setting window focus when creating new windows
func addNewNoteWindow() {
    let newWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    
    // Configure window properties...
    newWindow.titlebarAppearsTransparent = true
    newWindow.styleMask.insert(.fullSizeContentView)
    newWindow.isOpaque = false
    newWindow.backgroundColor = .clear
    newWindow.level = .floating
    newWindow.collectionBehavior = .canJoinAllSpaces
    
    // Create and set content view
    let noteView = NoteView(window: newWindow)
    newWindow.contentView = NSHostingView(rootView: noteView)
    newWindow.delegate = self
    
    openWindows.append(newWindow)
    
    // 🔑 KEY: This makes the window focused and brings it to front
    newWindow.makeKeyAndOrderFront(nil)
    
    print("WindowManager: New window created and focused")
}
```

### 2. Content-Level Focus with `@FocusState`

Within the SwiftUI view, use `@FocusState` to manage focus for specific UI elements:

```swift
// ContentView.swift - NoteView focus management
struct NoteView: View {
    @State private var noteText: String
    weak var window: NSWindow?
    
    // 🔑 KEY: FocusState to manage text editor focus
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            TextEditor(text: $noteText)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .scrollIndicators(.never)
                .padding(.leading, 10)
        }
        .focusable() // Make the view focusable
        .focused($isFocused) // Bind focus state
        .onAppear {
            // 🔑 KEY: Set focus when view appears
            isFocused = true
            print("NoteView: Focus set to text editor")
        }
        .onDisappear {
            // Clean up focus when view disappears
            isFocused = false
        }
        // ... other modifiers
    }
}
```

### 3. Focus Management for Existing Windows

For windows that already exist but need to be brought to focus:

```swift
// WindowManager.swift - Bringing existing windows to focus
func showNotesListWindow() {
    if let existingWindow = notesListWindow, existingWindow.isVisible {
        // 🔑 KEY: Bring existing window to front and focus
        existingWindow.makeKeyAndOrderFront(nil)
        print("WindowManager: Notes list window brought to front and focused")
        return
    }
    
    // Create new window if it doesn't exist...
    let newWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    
    // Configure window...
    newWindow.title = "All Notes"
    newWindow.titlebarAppearsTransparent = true
    newWindow.styleMask.insert(.fullSizeContentView)
    newWindow.isOpaque = false
    newWindow.backgroundColor = .clear
    newWindow.level = .floating
    newWindow.collectionBehavior = .canJoinAllSpaces
    
    newWindow.contentView = NSHostingView(rootView: NotesListView())
    newWindow.delegate = self
    
    notesListWindow = newWindow
    
    // 🔑 KEY: Focus the new window
    newWindow.makeKeyAndOrderFront(nil)
    print("WindowManager: Notes list window created and focused")
}
```

### 4. Focus Management in List Views

For views that contain multiple focusable elements:

```swift
// NotesListView.swift - Managing focus in list views
struct NotesListView: View {
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            // Search field and other content...
            TextField("Search notes...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // List content...
            ScrollView {
                // Note items...
            }
        }
        .focusable() // Make the entire view focusable
        .focused($isFocused) // Bind focus state
        .onAppear {
            // 🔑 KEY: Set focus when the view appears
            isFocused = true
            print("NotesListView: Focus set to list view")
        }
        .onDisappear {
            isFocused = false
        }
        .onExitCommand {
            // Handle ESC key to close window
            WindowManager.shared.closeNotesListWindow()
        }
    }
}
```

## Advanced Focus Techniques

### 1. Delayed Focus Setting

Sometimes you need to delay focus setting to ensure the view hierarchy is fully established:

```swift
.onAppear {
    // Delay focus setting to ensure view is ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isFocused = true
    }
}
```

### 2. Focus Transfer Between Elements

For complex forms or multi-element views:

```swift
struct ComplexView: View {
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case title, content, search
    }
    
    var body: some View {
        VStack {
            TextField("Title", text: $title)
                .focused($focusedField, equals: .title)
            
            TextEditor(text: $content)
                .focused($focusedField, equals: .content)
            
            TextField("Search", text: $search)
                .focused($focusedField, equals: .search)
        }
        .onAppear {
            // Set initial focus to the first field
            focusedField = .title
        }
        .onSubmit {
            // Move focus to next field on Enter
            switch focusedField {
            case .title:
                focusedField = .content
            case .content:
                focusedField = .search
            case .search:
                // Handle final submission
                break
            case .none:
                break
            }
        }
    }
}
```

### 3. Window Activation Handling

Handle cases where windows become active/inactive:

```swift
// In WindowManager or view controller
func windowDidBecomeKey(_ notification: Notification) {
    // Window became the key window (focused)
    print("Window became key - setting content focus")
    
    // You can post a notification or use other mechanisms to inform SwiftUI views
    NotificationCenter.default.post(name: .windowDidBecomeKey, object: notification.object)
}

func windowDidResignKey(_ notification: Notification) {
    // Window lost focus
    print("Window resigned key - removing content focus")
}
```

### 4. Focus Restoration

Restore focus when returning to a window:

```swift
struct NoteView: View {
    @FocusState private var isFocused: Bool
    @State private var shouldRestoreFocus = false
    
    var body: some View {
        // ... content
        .focused($isFocused)
        .onReceive(NotificationCenter.default.publisher(for: .windowDidBecomeKey)) { notification in
            if let window = notification.object as? NSWindow,
               window === self.window {
                // This window became key, restore focus
                isFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .windowDidResignKey)) { notification in
            if let window = notification.object as? NSWindow,
               window === self.window {
                // This window lost focus, remember to restore later
                shouldRestoreFocus = isFocused
                isFocused = false
            }
        }
    }
}
```

## Focus Flow Best Practices

### 1. Immediate Focus for New Windows

```swift
// ✅ Good: Set focus immediately when window appears
newWindow.makeKeyAndOrderFront(nil)

// ❌ Avoid: Creating window without focusing
newWindow.orderFront(nil) // Window appears but doesn't get focus
```

### 2. Proper Focus State Management

```swift
// ✅ Good: Manage focus state properly
.onAppear {
    isFocused = true
}
.onDisappear {
    isFocused = false
}

// ❌ Avoid: Leaving focus state inconsistent
.onAppear {
    isFocused = true
}
// Missing onDisappear cleanup
```

### 3. Accessibility Considerations

```swift
// ✅ Good: Consider accessibility
TextEditor(text: $noteText)
    .focused($isFocused)
    .accessibilityLabel("Note content")
    .accessibilityHint("Text editor for writing notes")

// ❌ Avoid: Missing accessibility information
TextEditor(text: $noteText)
    .focused($isFocused)
```

## Common Focus Issues and Solutions

### Issue 1: Window appears but no keyboard input

**Problem**: Window is visible but doesn't receive keyboard input.

**Solution**: Ensure `makeKeyAndOrderFront(nil)` is called:

```swift
// Fix:
newWindow.makeKeyAndOrderFront(nil) // Not just orderFront(nil)
```

### Issue 2: Focus state not updating

**Problem**: `@FocusState` doesn't reflect actual focus.

**Solution**: Properly bind and update focus state:

```swift
// Fix:
.focused($isFocused)
.onAppear { isFocused = true }
.onDisappear { isFocused = false }
```

### Issue 3: Multiple windows fighting for focus

**Problem**: Multiple windows trying to grab focus simultaneously.

**Solution**: Coordinate focus management:

```swift
// Fix: Only focus the most recently created window
private var lastCreatedWindow: NSWindow?

func addNewNoteWindow() {
    // ... create window
    lastCreatedWindow = newWindow
    newWindow.makeKeyAndOrderFront(nil)
}
```

### Issue 4: Focus lost after window operations

**Problem**: Focus disappears after window resize, move, etc.

**Solution**: Restore focus after operations:

```swift
// Fix: Restore focus after window operations
func windowDidEndLiveResize(_ notification: Notification) {
    // Restore focus after resize
    if let window = notification.object as? NSWindow {
        window.makeKey()
    }
}
```

## Testing Focus Behavior

### Manual Testing Checklist

1. **New Window Creation**: Can you type immediately after creating a new window?
2. **Window Switching**: Does focus work when switching between windows?
3. **Multiple Windows**: Do new windows properly steal focus from existing ones?
4. **Keyboard Navigation**: Can you navigate using Tab/Shift+Tab?
5. **ESC Handling**: Does ESC properly close focused windows?

### Debugging Focus Issues

```swift
// Add logging to track focus changes
.focused($isFocused)
.onChange(of: isFocused) { oldValue, newValue in
    print("Focus changed from \(oldValue) to \(newValue)")
}

// Monitor window key status
func windowDidBecomeKey(_ notification: Notification) {
    print("Window became key: \(notification.object)")
}

func windowDidResignKey(_ notification: Notification) {
    print("Window resigned key: \(notification.object)")
}
```

## Summary

Proper focus management in SwiftUI/macOS applications requires coordination between:

1. **AppKit Level**: Using `makeKeyAndOrderFront(_:)` for window focus
2. **SwiftUI Level**: Using `@FocusState` for content focus
3. **Lifecycle Management**: Proper setup in `onAppear`/`onDisappear`
4. **State Coordination**: Ensuring focus state reflects actual focus

Following these patterns ensures users can immediately interact with new windows without additional clicks, creating a smooth and intuitive user experience. 