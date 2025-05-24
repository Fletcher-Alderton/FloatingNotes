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
            .padding(.top, 8)
            .padding(.leading, 16) // Add leading padding to align with row content
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure it takes available width
            .background(Color.clear) // Make the background transparent
            // Optionally, add the visual effect view if you want the header area itself to have the blur/translucency effect.
            // For now, let's stick to clear to ensure the underlying VisualEffectView of the window shows through.
    }
}

struct NotesListView: View {
    @StateObject private var notesManager = NotesManager()
    @State private var searchText: String = ""
    // State to manage the presentation of the confirmation dialog
    @State private var showingDeleteConfirm: Bool = false
    @State private var noteToDelete: NoteItem? = nil

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
                    .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(EdgeInsets(top: 12, leading: 12, bottom: 8, trailing: 12))
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
                                    .padding(.vertical, 4) // Add vertical padding to rows
                                    .padding(.horizontal, 12) // Add horizontal padding to rows
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
                                    .padding(.vertical, 4) // Add vertical padding to rows
                                    .padding(.horizontal, 12) // Add horizontal padding to rows
                            }
                            if unpinnedNotes.isEmpty && searchText.isEmpty && pinnedNotes.isEmpty {
                                Text("No notes found. Create one!")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12) // Add horizontal padding
                            } else if unpinnedNotes.isEmpty && !searchText.isEmpty {
                                 Text("No notes match your search.")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12) // Add horizontal padding
                            }
                        }
                    }
                    .padding(.vertical, 8) // Add vertical padding to the VStack content
                }
            }
        }
        .frame(minWidth: 300, idealWidth: 350, maxWidth: .infinity, minHeight: 200, idealHeight: 400, maxHeight: .infinity)
        .onAppear {
            loadNotes()
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
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Example subtitle - you can customize this
                Text("Opened recently \u{2022} \(note.url.lastPathComponent.count) Characters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    togglePin(note: note)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(note.isPinned ? .yellow : .secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help(note.isPinned ? "Unpin note" : "Pin note")

                Button {
                    self.noteToDelete = note
                    self.showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Delete note")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
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
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("FloatingNotesApp")
    }

    func loadNotes() {
        let notesDirectory = getAppNotesDirectory()
        var loadedNotes: [NoteItem] = []
        let pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: notesDirectory,
                                                                   includingPropertiesForKeys: [.contentModificationDateKey, .nameKey],
                                                                   options: .skipsHiddenFiles)
            for url in fileURLs {
                if url.pathExtension == "md" {
                    let filename = url.lastPathComponent
                    let components = filename.replacingOccurrences(of: ".md", with: "").split(separator: "_")
                    let title = components.dropLast().joined(separator: "_")
                    let idString = String(components.last ?? "")
                    
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let modificationDate = attributes[.modificationDate] as? Date

                    if let uuid = UUID(uuidString: idString) {
                        let isPinned = pinnedIDs.contains(uuid.uuidString)
                        loadedNotes.append(NoteItem(id: uuid, title: title.isEmpty ? "Untitled Note" : title, url: url, isPinned: isPinned, lastModified: modificationDate))
                    } else {
                        let fallbackTitle = filename.replacingOccurrences(of: ".md", with: "")
                        // Notes that couldn't parse a UUID from filename won't be able to persist pinning by ID.
                        // They will always appear unpinned unless their filename format is corrected.
                        loadedNotes.append(NoteItem(id: UUID(), title: fallbackTitle, url: url, isPinned: false, lastModified: modificationDate))
                         print("Could not parse UUID from filename: \(filename). Using filename as title and new UUID. Pinning may not work for this note.")
                    }
                }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
        self.notesManager.notes = loadedNotes // Sorting is now handled by filteredNotes
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
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView()
    }
} 