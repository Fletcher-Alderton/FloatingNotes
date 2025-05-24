import SwiftUI
import AppKit

// Class to manage window lifecycle and retention
class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()
    private var openWindows: [NSWindow] = []

    private override init() { // Private init for singleton
        super.init()
    }

    func addNewNoteWindow() {
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Configure frame
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let xOffset = CGFloat.random(in: -40...40)
            let yOffset = CGFloat.random(in: -40...40)
            let newOriginX = (screenRect.width - newWindow.frame.width) / 2 + xOffset
            let newOriginY = (screenRect.height - newWindow.frame.height) / 2 + yOffset
            newWindow.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
        }

        // Apply all styling directly here
        newWindow.titlebarAppearsTransparent = true
        newWindow.styleMask.insert(.fullSizeContentView)
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.level = .floating // Make the window float
        
        // Create NoteView with a reference to its window.
        let noteView = NoteView(window: newWindow) // Window is now fully configured
        newWindow.contentView = NSHostingView(rootView: noteView)
        newWindow.delegate = self // For windowWillClose
        
        openWindows.append(newWindow)
        newWindow.makeKeyAndOrderFront(nil)
        print("WindowManager: New window created and styled. Total managed windows: \(openWindows.count)")
    }

    // NSWindowDelegate method
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        openWindows.removeAll { $0 === window } // Remove from our tracking array
        print("WindowManager: Window closed. Total managed windows: \(openWindows.count)")
    }
}

// NSViewRepresentable wrapper for NSVisualEffectView
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

// The view representing the content inside the note window
struct NoteView: View {
    // State variable to hold the text content of the note
    // @State ensures the view updates when the text changes
    @State private var noteText: String = ""
    // Add a weak reference to the window
    weak var window: NSWindow?

    var body: some View {
        ZStack {
            // Background visual effect
            VisualEffectView()
                .ignoresSafeArea()
            
            // Use TextEditor for a multi-line editable text area
            TextEditor(text: $noteText)
                .scrollContentBackground(.hidden) // Hide the default background
                .background(.clear) // Make TextEditor background transparent
                .font(.system(size: 14)) // Set a nice font size
                .foregroundColor(.primary) // Ensure text is visible
                .scrollIndicators(.never)
                .padding(.leading, 10)
                //.padding(.trailing, 10)
                //.padding(.top, 10)
                //.padding(.bottom, 10)
        }
        .onAppear {
            print("NoteView onAppear: self.window is nil? \(self.window == nil)")
            // Window is configured by WindowManager before NoteView appears.
            // Only need to set the initial title.
            if self.window != nil {
                print("NoteView onAppear: Window IS SET. Calling updateTitleBasedOnText.")
                updateTitleBasedOnText()
            } else {
                // This case should ideally not be hit if WindowManager always provides a window.
                print("NoteView onAppear: Window IS NIL. Cannot set initial title.")
            }
        }
        .onChange(of: noteText) { newValue in
            self.updateTitleBasedOnText()
        }
        .onChange(of: window) { oldWindow, newWindow in
            // This onChange for the window property itself might be less critical now,
            // as the window is provided at init.
            // However, if it does change (e.g. from nil to non-nil in some other scenario),
            // ensuring the title is updated is good.
            print("NoteView onChange(of: window): oldWindow is nil? \(oldWindow == nil), newWindow is nil? \(newWindow == nil)")
            if oldWindow == nil && newWindow != nil {
                print("NoteView onChange(of: window): Window transitioned from NIL to SET. Calling updateTitleBasedOnText.")
                updateTitleBasedOnText() // Ensure title is set if window reference changes
            }
        }
        // Add a toolbar to the window containing buttons
        .toolbar {
            // Place the toolbar items on the trailing side (right side)
            ToolbarItemGroup(placement: .automatic) {
                // Button 1 (Command mode icon)
                Button {
                    // Action for grid button tapped
                    print("Commmand button tapped")
                } label: {
                    // Using SF Symbols for the icons
                    Label("Command", systemImage: "command")
                }

                // Button 2 (List mode icon)
                Button {
                    // Action for list button tapped
                    print("List button tapped")
                } label: {
                    Label("List", systemImage: "list.bullet")
                }

                // Button 3 (Add New Note icon)
                Button {
                    // Action for add new note button
                    WindowManager.shared.addNewNoteWindow() // Use the window manager
                } label: {
                    Label("Add New Note", systemImage: "plus")
                }
            }
        }
    }
    
    private func setTitle(title: String) {
        // Use the window reference
        window?.title = title
    }
    
    private func updateTitleBasedOnText() {
        if let firstLine = noteText.components(separatedBy: .newlines).first, !firstLine.isEmpty {
            self.setTitle(title: firstLine)
        } else {
            self.setTitle(title: "Untitled Note")
        }
    }
}

// Optional: Preview Provider for Xcode Canvas (mainly for iOS/iPadOS previews,
// less critical for simple macOS views but can still be useful)
/*
#Preview {
    NoteView()
}
*/
