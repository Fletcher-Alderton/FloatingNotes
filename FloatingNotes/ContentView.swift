import SwiftUI
import AppKit
import SwiftDown

// TODO:
// - Replace the settings link with a pin button that will enable (canJoinAllSpaces) or disable (canJoinAllSpaces) the window to follow the user across spaces.

// Custom NSHostingView that disables focus ring
class NoFocusRingHostingView<Content: View>: NSHostingView<Content> {
    override var focusRingType: NSFocusRingType {
        get { return .none }
        set { }
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
}

// Class to manage window lifecycle and retention
class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()
    private var openWindows: [NSWindow] = []
    private var notesListWindow: NSWindow? // To hold a reference to the notes list window

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
        newWindow.collectionBehavior = .canJoinAllSpaces // Show on all spaces
        
        // Create NoteView with a reference to its window.
        let noteView = NoteView(window: newWindow) // Window is now fully configured
        let hostingView = NoFocusRingHostingView(rootView: noteView)
        newWindow.contentView = hostingView
        newWindow.delegate = self // For windowWillClose
        
        openWindows.append(newWindow)
        newWindow.makeKeyAndOrderFront(nil)
        print("WindowManager: New window created and styled. Total managed windows: \(openWindows.count)")
    }

    func addNewNoteWindow(withInitialText initialText: String) {
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
        newWindow.collectionBehavior = .canJoinAllSpaces // Show on all spaces
        newWindow.hasShadow = false // Remove window shadow/border
        newWindow.standardWindowButton(.closeButton)?.isHidden = false
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = false
        newWindow.standardWindowButton(.zoomButton)?.isHidden = false
        
        // Create NoteView with initial text and a reference to its window.
        let noteView = NoteView(initialText: initialText, window: newWindow, sourceURL: nil)
        let hostingView = NoFocusRingHostingView(rootView: noteView)
        newWindow.contentView = hostingView
        newWindow.delegate = self // For windowWillClose
        
        openWindows.append(newWindow)
        newWindow.makeKeyAndOrderFront(nil)
        print("WindowManager: New window created with initial text and styled. Total managed windows: \(openWindows.count)")
    }

    func openNoteFromURL(url: URL) {
        // Prevent duplicate windows: bring existing note window to front if it's already open
        for window in openWindows {
            if window.representedURL == url {
                window.makeKeyAndOrderFront(nil)
                print("WindowManager: Note window for URL \(url.lastPathComponent) already open, bringing to front.")
                return
            }
        }

        // Attempt to read the content from the URL
        var noteContent: String
        do {
            noteContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("WindowManager: Error reading note content from URL \(url.path): \(error)")
            // Optionally, show an error to the user (e.g., a new empty note or an alert)
            // For now, create a new empty note window if reading fails.
            addNewNoteWindow()
            return
        }

        // Create a new window for the note content
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let xOffset = CGFloat.random(in: -40...40)
            let yOffset = CGFloat.random(in: -40...40)
            let newOriginX = (screenRect.width - newWindow.frame.width) / 2 + xOffset
            let newOriginY = (screenRect.height - newWindow.frame.height) / 2 + yOffset
            newWindow.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
        }

        newWindow.titlebarAppearsTransparent = true
        newWindow.styleMask.insert(.fullSizeContentView)
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.level = .floating
        newWindow.collectionBehavior = .canJoinAllSpaces // Show on all spaces
        newWindow.hasShadow = false // Remove window shadow/border
        newWindow.standardWindowButton(.closeButton)?.isHidden = false
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = false
        newWindow.standardWindowButton(.zoomButton)?.isHidden = false

        // Create NoteView with the loaded content and its window.
        // We need to modify NoteView to accept initial text and potentially the URL for saving purposes.
        let noteView = NoteView(initialText: noteContent, window: newWindow, sourceURL: url)
        let hostingView = NoFocusRingHostingView(rootView: noteView)
        newWindow.contentView = hostingView
        newWindow.delegate = self
        newWindow.representedURL = url

        openWindows.append(newWindow)
        newWindow.makeKeyAndOrderFront(nil)
        print("WindowManager: Opened note from URL. Total managed windows: \(openWindows.count)")
    }

    func showNotesListWindow() {
        if let existingWindow = notesListWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil) // Bring to front if already open
            print("WindowManager: Notes list window already open. Bringing to front.")
            return
        }

        let notesListHostingView = NoFocusRingHostingView(rootView: NotesListView())
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500), // Adjust size as needed
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "All Notes"
        
        // Apply the same styling as note windows for consistency
        newWindow.titlebarAppearsTransparent = true
        newWindow.styleMask.insert(.fullSizeContentView)
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.level = .floating // Make the window float like note windows
        newWindow.collectionBehavior = .canJoinAllSpaces // Show on all spaces
        newWindow.hasShadow = false // Remove window shadow/border
        newWindow.standardWindowButton(.closeButton)?.isHidden = false
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = false
        newWindow.standardWindowButton(.zoomButton)?.isHidden = false
        
        newWindow.contentView = notesListHostingView
        newWindow.isReleasedWhenClosed = false // Important: Keep the window instance around
        newWindow.delegate = self // Handle close event

        // Center the window
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newOriginX = (screenRect.width - newWindow.frame.width) / 2
            let newOriginY = (screenRect.height - newWindow.frame.height) / 2
            newWindow.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
        }

        notesListWindow = newWindow // Store reference
        newWindow.makeKeyAndOrderFront(nil)
        print("WindowManager: Notes list window created and shown with note-style appearance.")
    }

    func openLastNoteOrCreateNew() {
        let notesDirectory = Self.getAppNotesDirectory()
        
        // Get all .md files in the notes directory
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: notesDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "md" }
            
            if fileURLs.isEmpty {
                // No notes exist, create a new one
                print("WindowManager: No existing notes found. Creating new note.")
                addNewNoteWindow()
                return
            }
            
            // Find the most recently modified note
            let sortedFiles = try fileURLs.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                let date2 = try url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                return date1 > date2
            }
            
            if let mostRecentNote = sortedFiles.first {
                print("WindowManager: Opening most recent note: \(mostRecentNote.lastPathComponent)")
                openNoteFromURL(url: mostRecentNote)
            } else {
                // Fallback to creating new note
                print("WindowManager: Could not determine most recent note. Creating new note.")
                addNewNoteWindow()
            }
            
        } catch {
            print("WindowManager: Error accessing notes directory: \(error). Creating new note.")
            addNewNoteWindow()
        }
    }

    // NSWindowDelegate method
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if window === notesListWindow {
            notesListWindow = nil // Clear the reference when the notes list window is closed
            print("WindowManager: Notes list window closed.")
        } else {
            openWindows.removeAll { $0 === window } // Remove from our tracking array for note windows
            print("WindowManager: Note window closed. Total managed note windows: \(openWindows.count)")
        }
    }

    func closeNotesListWindow() {
        notesListWindow?.close()
        print("WindowManager: Notes list window closed via closeNotesListWindow()")
    }

    // Static helper to get the app's documents directory + app-specific subfolder
    static func getAppNotesDirectory() -> URL {
        let customNotesDirectoryKey = "customNotesDirectory"
        
        // Check if user has set a custom directory
        if let customPath = UserDefaults.standard.string(forKey: customNotesDirectoryKey),
           !customPath.isEmpty {
            let customURL = URL(fileURLWithPath: customPath)
            // Verify the directory exists and is accessible
            if FileManager.default.fileExists(atPath: customURL.path) {
                return customURL
            } else {
                // If custom directory doesn't exist, try to create it
                do {
                    try FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true, attributes: nil)
                    return customURL
                } catch {
                    print("WindowManager: Error creating custom notes directory: \(error). Falling back to default.")
                    // Fall back to default if custom directory can't be created
                }
            }
        }
        
        // Default behavior - use Documents/FloatingNotesApp
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let appDirectory = paths[0].appendingPathComponent("FloatingNotesApp")
        
        // Ensure the subdirectory exists
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                print("WindowManager: Created FloatingNotesApp directory at: \(appDirectory.path)")
            } catch {
                print("WindowManager: Error creating FloatingNotesApp directory: \(error)")
            }
        }
        return appDirectory
    }
}

// NSViewRepresentable wrapper for NSVisualEffectView
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        return visualEffect
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}

// Add this class before the NoteView struct
class WindowResizeObserver: NSObject {
    var onWindowResize: (() -> Void)?
    
    @objc func windowDidResize(_ notification: Notification) {
        onWindowResize?()
    }
}

// The view representing the content inside the note window
struct NoteView: View {
    // State variable to hold the text content of the note
    // @State ensures the view updates when the text changes
    @State private var noteText: String
    // Add a weak reference to the window
    weak var window: NSWindow?
    // Store the source URL if the note was opened from a file
    @State private var sourceURL: URL?
    
    // AppStorage for default pin setting
    @AppStorage("defaultIsPinned") private var defaultIsPinned: Bool = true

    let noteID: UUID // Unique ID for each note instance
    @State private var lastSavedFilenameComponent: String? // To track the filename for renames
    @State private var isPinned: Bool
    @FocusState private var isFocused: Bool
    
    // Auto-sizing properties
    @State private var isAutoSizingEnabled: Bool = true
    @State private var hasUserManuallyResized: Bool = false
    @State private var resizeObserver: WindowResizeObserver? = nil
    @State private var showAutoSizeButton: Bool = false
    @State private var hideButtonTask: Task<Void, Never>? = nil
    
    // Constants for auto-sizing
    private let minWindowHeight: CGFloat = 150
    private let maxAutoSizeHeight: CGFloat = 600
    private let lineHeight: CGFloat = 20 // Approximate line height
    private let basePadding: CGFloat = 80 // Title bar + padding

    // Initializer for new notes
    init(window: NSWindow?) {
        _noteText = State(initialValue: "")
        self.window = window
        self.noteID = UUID() // New note, new ID
        self._sourceURL = State(initialValue: nil)
        self._isPinned = State(initialValue: UserDefaults.standard.object(forKey: "defaultIsPinned") as? Bool ?? true)
        print("NoteView init (new note): self.window is nil? \(self.window == nil), noteID: \(self.noteID)")
    }

    // Initializer for notes opened from a URL
    init(initialText: String, window: NSWindow?, sourceURL: URL?) {
        _noteText = State(initialValue: initialText)
        self.window = window
        self._sourceURL = State(initialValue: sourceURL)
        self._isPinned = State(initialValue: UserDefaults.standard.object(forKey: "defaultIsPinned") as? Bool ?? true)

        // Attempt to parse UUID from filename if sourceURL is provided
        if let url = sourceURL,
           let lastPathComponent = url.lastPathComponent.components(separatedBy: ".md").first,
           let uuidString = lastPathComponent.split(separator: "_").last,
           let uuid = UUID(uuidString: String(uuidString)) {
            self.noteID = uuid
            self.lastSavedFilenameComponent = url.lastPathComponent // Keep track of the original filename
        } else {
            self.noteID = UUID() // Fallback to new UUID if parsing fails
        }
        print("NoteView init (from URL): self.window is nil? \(self.window == nil), noteID: \(self.noteID), sourceURL: \(sourceURL?.absoluteString ?? "nil")")
    }

    // Hover area view for auto-size button overlay, to simplify the body
    private var autoSizeHoverArea: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(maxWidth: .infinity, maxHeight: 20)
            .onContinuousHover { phase in
                switch phase {
                case .active(_):
                    hideButtonTask?.cancel()
                    hideButtonTask = nil
                    showAutoSizeButton = true
                case .ended:
                    hideButtonTask?.cancel()
                    hideButtonTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        if !Task.isCancelled {
                            await MainActor.run {
                                showAutoSizeButton = false
                            }
                        }
                    }
                }
            }
    }

    var body: some View {
        ZStack {
            // Background visual effect
            VisualEffectView()
                .ignoresSafeArea()
            
            // Use TextEditor for a multi-line editable text area
            SwiftDownEditor(text: $noteText)
                .insetsSize(10)
                .theme(Theme.BuiltIn.defaultClear.theme())
                .scrollContentBackground(.hidden) // Hide the default background
                .background(.clear) // Make TextEditor background transparent
                .font(.system(size: 14)) // Set a nice font size
                .foregroundColor(.primary) // Ensure text is visible
                .scrollIndicators(.never)
                .padding(.leading, 10)
                //.padding(.trailing, 10)
                //.padding(.top, 10)
                //.padding(.bottom, 10)
            
            // Auto-size hover area always visible
            VStack {
                Spacer()
                autoSizeHoverArea
            }

            // Auto-size button overlay
            if showAutoSizeButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            hasUserManuallyResized = false
                            isAutoSizingEnabled = true
                            adjustWindowSizeForText()
                            showAutoSizeButton = false
                            // Cancel any pending hide task since we're manually hiding
                            hideButtonTask?.cancel()
                            hideButtonTask = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .font(.system(size: 12))
                                Text("Auto Size")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(_):
                                hideButtonTask?.cancel()
                                hideButtonTask = nil
                                showAutoSizeButton = true
                            case .ended:
                                hideButtonTask?.cancel()
                                hideButtonTask = Task {
                                    try? await Task.sleep(nanoseconds: 200_000_000)
                                    if !Task.isCancelled {
                                        await MainActor.run {
                                            showAutoSizeButton = false
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.2), value: showAutoSizeButton)
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            print("NoteView onAppear: self.window is nil? \(self.window == nil)")
            // Window is configured by WindowManager before NoteView appears.
            // Only need to set the initial title.
            if self.window != nil {
                print("NoteView onAppear: Window IS SET. Calling updateTitleBasedOnText.")
                updateTitleBasedOnText()
                saveNoteToFile() // Save initial state (e.g., empty note)
                setupWindowResizeObserver() // Setup resize observer
                adjustWindowSizeForText() // Initial size adjustment
            } else {
                // This case should ideally not be hit if WindowManager always provides a window.
                print("NoteView onAppear: Window IS NIL. Cannot set initial title.")
            }
            isFocused = true
        }
        .onDisappear {
            isFocused = false
            cleanupWindowResizeObserver()
            // Cancel any pending hide task
            hideButtonTask?.cancel()
            hideButtonTask = nil
        }
        .onExitCommand {
            // Close the window when ESC is pressed
            window?.close()
            print("NoteView onExitCommand: Window closed")
        }
        .onChange(of: noteText) {
            self.updateTitleBasedOnText()
            self.saveNoteToFile() // Save content whenever text changes
            if isAutoSizingEnabled && !hasUserManuallyResized {
                adjustWindowSizeForText()
            }
        }
        .onChange(of: window) { oldWindow, newWindow in
            // Handle window reference changes
            print("NoteView onChange(of: window): oldWindow is nil? \(oldWindow == nil), newWindow is nil? \(newWindow == nil)")
            if oldWindow == nil && newWindow != nil {
                print("NoteView onChange(of: window): Window transitioned from NIL to SET. Calling updateTitleBasedOnText.")
                updateTitleBasedOnText()
                setupWindowResizeObserver()
                adjustWindowSizeForText()
            }
        }
        // Add a toolbar to the window containing buttons
        .toolbar {
            // Place the toolbar items on the trailing side (right side)
            ToolbarItemGroup(placement: .automatic) {
                // Pin Button
                Button {
                    isPinned.toggle()
                    if let window = window {
                        if isPinned {
                            window.collectionBehavior = .canJoinAllSpaces
                        } else {
                            window.collectionBehavior = .managed
                        }
                    }
                } label: {
                    Label("Pin", systemImage: isPinned ? "pin.fill" : "pin")
                }

                // Button 2 (List mode icon)
                Button {
                    // Action for list button tapped
                    print("List button tapped")
                    WindowManager.shared.showNotesListWindow() // Show the notes list window
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

    private func saveNoteToFile() {
        // Check if the note has any content (non-whitespace text)
        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            print("NoteView: Note is empty, skipping save")
            return
        }
        
        let notesDirectory = getAppNotesDirectory()

        let currentFirstLine = noteText.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let titleForFilename = currentFirstLine.isEmpty ? "Untitled Note" : currentFirstLine
        
        let sanitizedTitlePart = sanitizeFilenameString(titleForFilename)
        // Use the existing noteID for the filename to ensure consistency
        let newFilenameComponent = "\(sanitizedTitlePart)_\(noteID.uuidString).md"
        let newFileURL = notesDirectory.appendingPathComponent(newFilenameComponent)

        // If a sourceURL exists and its last path component is different from newFilenameComponent,
        // it means the note was opened from a file and its title (first line) has changed.
        // In this case, the old file (from sourceURL) should be deleted after saving the new one.
        var oldFileURLToDelete: URL? = nil
        if let srcURL = sourceURL, srcURL.lastPathComponent != newFilenameComponent {
            oldFileURLToDelete = srcURL
        } else if let oldFilename = lastSavedFilenameComponent, oldFilename != newFilenameComponent {
            // This handles the case where a new note (no sourceURL) is renamed
            // or an opened note is renamed multiple times.
            oldFileURLToDelete = notesDirectory.appendingPathComponent(oldFilename)
        }

        // Save the current note text to the new file
        do {
            try noteText.write(to: newFileURL, atomically: true, encoding: .utf8)
            lastSavedFilenameComponent = newFilenameComponent // Update the record of the last saved filename
            // If this note was opened from a URL, update its sourceURL to the new file URL
            // This is important if the note is renamed multiple times.
            if self.sourceURL != nil {
                self.sourceURL = newFileURL
            }
            print("NoteView: Saved note to \(newFileURL.path)")

            // After successful save, delete the old file if applicable
            if let oldURL = oldFileURLToDelete {
                if FileManager.default.fileExists(atPath: oldURL.path) {
                    do {
                        try FileManager.default.removeItem(at: oldURL)
                        print("NoteView: Removed old file: \(oldURL.lastPathComponent)")
                    } catch {
                        print("NoteView: Error removing old file '\(oldURL.lastPathComponent)': \(error).")
                        // Log error, but don't let it block the main functionality.
                    }
                }
            }
        } catch {
            print("NoteView: CRITICAL - Error saving note to '\(newFileURL.path)': \(error)")
        }
    }

    // Helper to get the app's documents directory + app-specific subfolder
    private func getAppNotesDirectory() -> URL {
        return WindowManager.getAppNotesDirectory()
    }

    // Helper to sanitize a string for use in a filename
    private func sanitizeFilenameString(_ string: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\\\?%*|\"<>:")
        var sanitized = string
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_") // Replace invalid characters with underscore
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If the string becomes empty after sanitization (e.g., it was only invalid characters),
        // provide a default name.
        if sanitized.isEmpty {
            sanitized = "Untitled"
        }

        // Limit the length of the descriptive part of the filename to prevent overly long names.
        let maxLength = 50
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }
        return sanitized
    }

    private func setupWindowResizeObserver() {
        guard let window = window else { return }
        
        // Clean up any existing observer
        cleanupWindowResizeObserver()
        
        // Add observer for window resize events
        resizeObserver = WindowResizeObserver()
        resizeObserver?.onWindowResize = {
            // Mark that user has manually resized if auto-sizing is enabled
            if self.isAutoSizingEnabled {
                print("User manually resized window - disabling auto-sizing")
                self.hasUserManuallyResized = true
                // hide the auto-size button by default only show when the user hovers over autosizehoverarea
                self.showAutoSizeButton = false
            }
        }
        NotificationCenter.default.addObserver(resizeObserver as Any, selector: #selector(WindowResizeObserver.windowDidResize(_:)), name: NSWindow.didResizeNotification, object: window)
    }
    
    private func cleanupWindowResizeObserver() {
        if let observer = resizeObserver {
            NotificationCenter.default.removeObserver(observer)
            resizeObserver = nil
        }
    }
    
    private func adjustWindowSizeForText() {
        guard let window = window, isAutoSizingEnabled, !hasUserManuallyResized else { return }
        
        // Determine content width for text bounding
        let horizontalPadding: CGFloat = 20 // adjust according to TextEditor padding
        let contentWidth: CGFloat
        if let contentViewWidth = window.contentView?.frame.width {
            contentWidth = contentViewWidth - horizontalPadding
        } else {
            contentWidth = window.frame.width - horizontalPadding
        }

        // Compute bounding rect for text content
        let textNSString = noteText as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14)
        ]
        let boundingRect = textNSString.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        let contentHeight = boundingRect.height
        // Calculate total and final height
        let totalHeight = min(contentHeight + basePadding, maxAutoSizeHeight)
        let finalHeight = max(totalHeight, minWindowHeight)
        
        // Get current frame
        var newFrame = window.frame
        
        // Adjust height while keeping the top position fixed
        let heightDifference = finalHeight - newFrame.height
        newFrame.size.height = finalHeight
        newFrame.origin.y -= heightDifference // Move window down to keep top edge in place
        
        // Animate the resize
        window.setFrame(newFrame, display: true, animate: true)
        
        print("Auto-resized window to height: \(finalHeight) for \(contentHeight) lines")
    }
}
