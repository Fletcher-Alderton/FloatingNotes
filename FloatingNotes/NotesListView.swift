import SwiftUI
import Combine
import AppKit

// Custom transparent scroll view with auto-hiding scrollers
struct TransparentScrollView<Content: View>: NSViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // Configure scroll view properties for transparency and auto-hiding
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        // Configure the document view
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = hostingView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hostingView = nsView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content
        }
    }
}

// Custom view for transparent section headers
struct TransparentSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 6)
            .padding(.leading, 12) // Reduced leading padding
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
    }
}

struct NotesListView: View {
    @ObservedObject private var notesManager = NotesManager.shared
    @State private var searchText: String = ""
    // State to manage the presentation of the confirmation dialog
    @State private var showingDeleteConfirm: Bool = false
    @State private var noteToDelete: NoteItem? = nil
    @FocusState private var isFocused: Bool

    // Access the window manager
    // Note: Direct access like this isn't typical for standalone SwiftUI views,
    // but for this integrated context, it's a pragmatic way to open existing notes.
    // A more decoupled approach might use a shared environment object or service locator.
    private let windowManager = WindowManager.shared
    private let pinnedNotesKey = "pinnedNoteIDs" // UserDefaults key

    var body: some View {
        ZStack {
            // Background visual effect to match note windows
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Search Bar with translucent styling
                TextField("Search for notes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 6, trailing: 8))
                    .foregroundColor(.primary)

                // This ID changes when the pinned section's visibility should change,
                // forcing the List to re-evaluate its structure.
                // let listStructureId = "pinnedSectionVisible:\(!pinnedNotes.isEmpty)"

                TransparentScrollView { // Replace ScrollView with TransparentScrollView
                    VStack(alignment: .leading, spacing: 0) { // Add VStack inside ScrollView

                        // Pinned Section
                        if !pinnedNotes.isEmpty {
                            TransparentSectionHeader(title: "Pinned") // Use the header view
                            ForEach(pinnedNotes) { note in
                                noteRow(note: note)
                                    .padding(.vertical, 2) // Reduced vertical padding
                                    .frame(maxWidth: .infinity) // Center the note row
                            }
                        }

                        // Notes Section
                        // Show "Notes" header only if there are unpinned notes or if search is active (to clarify search results)
                        let unpinnedSectionHeader = ( !unpinnedNotes.isEmpty || !searchText.isEmpty ) ? "Notes" : ""
                        if !unpinnedSectionHeader.isEmpty || pinnedNotes.isEmpty { // Always show at least one section, or if searching
                            if !unpinnedSectionHeader.isEmpty {
                                TransparentSectionHeader(title: unpinnedSectionHeader) // Use the header view
                            }
                            ForEach(unpinnedNotes) { note in
                                noteRow(note: note)
                                    .padding(.vertical, 2) // Reduced vertical padding
                                    .frame(maxWidth: .infinity) // Center the note row
                            }
                            if unpinnedNotes.isEmpty && searchText.isEmpty && pinnedNotes.isEmpty {
                                Text("No notes found. Create one!")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8) // Reduced horizontal padding
                            } else if unpinnedNotes.isEmpty && !searchText.isEmpty {
                                 Text("No notes match your search.")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8) // Reduced horizontal padding
                            }
                        }
                    }
                    .padding(.vertical, 4) // Reduced vertical padding for the VStack content
                    .padding(.horizontal, 10) // Add horizontal padding to center content and leave room for scroll view
                }
            }
        }
        .frame(minWidth: 350, maxWidth: 350, minHeight: 400, maxHeight: .infinity) // Fixed size for width, flexible height
        .focusable()
        .focused($isFocused)
        .onAppear {
            loadNotes()
            isFocused = true
        }
        .onDisappear {
            isFocused = false
        }
        .onExitCommand {
            // Close the notes list window when ESC is pressed
            WindowManager.shared.closeNotesListWindow()
            print("NotesListView onExitCommand: Notes list window closed")
        }
        .alert(isPresented: $showingDeleteConfirm) {
            Alert(
                title: Text("Delete Note"),
                message: Text("Are you sure you want to delete \"\(noteToDelete?.title ?? "this note")\"? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let noteToDelete = noteToDelete {
                        deleteNote(note: noteToDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    // Helper view for note row
    private func noteRow(note: NoteItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) { // Reduced spacing between title and subtitle
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Subtitle with actual last open date and character count
                Text(subtitleText(for: note))
                    .font(.caption) // Changed from subheadline to caption for more compact display
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Allow text to take available space
            
            HStack(spacing: 6) { // Reduced spacing between buttons
                Button {
                    togglePin(note: note)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(note.isPinned ? .yellow : .secondary)
                        .font(.system(size: 14)) // Slightly smaller icons
                }
                .buttonStyle(BorderlessButtonStyle())
                .help(note.isPinned ? "Unpin note" : "Pin note")

                Button {
                    self.noteToDelete = note
                    self.showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14)) // Slightly smaller icons
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Delete note")
            }
            .frame(width: 60) // Fixed width for button area
        }
        .frame(width: 310) // Fixed width that leaves room for even padding and scroll view
        .padding(.vertical, 6) // Reduced vertical padding
        .padding(.horizontal, 10) // horizontal padding
        .background(Color.white.opacity(0.05))
        .cornerRadius(8) // Slightly smaller corner radius
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle()) // Make the whole row tappable
        .onTapGesture {
            openNote(note: note)
        }
        .onHover { isHovering in
            // Add subtle hover animation
            withAnimation(.easeInOut(duration: 0.2)) {
                // The hover effect is handled by SwiftUI's built-in behavior
                // We could add custom state here if needed
            }
        }
        .scaleEffect(1.0) // This enables subtle interaction feedback
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: note.isPinned)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    var filteredAndSortedNotes: [NoteItem] {
        // Apply search filter first
        let filtered = searchText.isEmpty ? notesManager.notes : notesManager.notes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        // Then sort: pinned first, then by modification date
        return filtered.sorted { (lhs, rhs) -> Bool in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned // Pinned items come before unpinned items
            }
            // If both have the same pinned status, sort by lastModified date (newest first)
            return (lhs.lastModified ?? Date.distantPast) > (rhs.lastModified ?? Date.distantPast)
        }
    }
    
    var pinnedNotes: [NoteItem] {
        filteredAndSortedNotes.filter { $0.isPinned }
    }

    var unpinnedNotes: [NoteItem] {
        filteredAndSortedNotes.filter { !$0.isPinned }
    }

    func getAppNotesDirectory() -> URL {
        return notesManager.getAppNotesDirectory()
    }

    func loadNotes() {
        notesManager.loadNotes()
    }

    func togglePin(note: NoteItem) {
        notesManager.togglePin(note: note)
    }

    func deleteNote(note: NoteItem) {
        notesManager.deleteNote(note: note)
    }

    func openNote(note: NoteItem) {
        // This is a placeholder for how you might open an existing note.
        // The actual implementation would depend on how `WindowManager` or your app
        // handles opening specific notes (e.g., by finding an existing window or creating a new one with content from URL).
        print("Attempting to open note: \(note.title) from \(note.url.path)")
        
        // For now, let's assume WindowManager has a method to open a note by URL
        // This is a conceptual call; the actual method needs to be implemented in WindowManager.
        windowManager.openNoteFromURL(url: note.url)
    }

    // Helper to generate subtitle text with actual last open date and word count
    private func subtitleText(for note: NoteItem) -> String {
        let wordCount = note.wordCount
        guard let lastModified = note.lastModified else {
            return "\(wordCount) Words"
        }
        let isRecent = lastModified > Date().addingTimeInterval(-86400)
        let dateString: String
        if isRecent {
            dateString = "Recently"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            dateString = formatter.string(from: lastModified)
        }
        return "\(dateString) \u{2022} \(wordCount) Words"
    }
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView()
    }
} 
