import Foundation
import Combine

class NotesManager: ObservableObject {
    static let shared = NotesManager()
    
    @Published var notes: [NoteItem] = []
    private let pinnedNotesKey = "pinnedNoteIDs" // UserDefaults key
    private let customNotesDirectoryKey = "customNotesDirectory" // UserDefaults key for custom directory
    private let directoryBookmarkKey = "directoryBookmark" // UserDefaults key for security-scoped bookmark
    private var currentSecurityScopedURL: URL? // Track currently accessed security-scoped URL
    private let indexFileName = "notes_index.json" // Index file name

    private init() {
        loadNotes()
    }
    
    deinit {
        // Clean up security-scoped resource access
        currentSecurityScopedURL?.stopAccessingSecurityScopedResource()
    }

    func getAppNotesDirectory() -> URL {
        // Clean up any previously accessed security-scoped resource
        if let previousURL = currentSecurityScopedURL {
            previousURL.stopAccessingSecurityScopedResource()
            currentSecurityScopedURL = nil
        }
        
        // Check if user has set a custom directory with security-scoped bookmark
        if let bookmarkData = UserDefaults.standard.data(forKey: directoryBookmarkKey) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
                
                if isStale {
                    print("Bookmark is stale, will need to re-select directory")
                    // Remove the stale bookmark
                    UserDefaults.standard.removeObject(forKey: directoryBookmarkKey)
                    UserDefaults.standard.removeObject(forKey: customNotesDirectoryKey)
                    UserDefaults.standard.synchronize()
                } else {
                    // Start accessing the security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        // Verify the directory still exists and is accessible
                        if FileManager.default.fileExists(atPath: url.path) {
                            currentSecurityScopedURL = url
                            return url
                        } else {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            } catch {
                print("Error resolving bookmark: \(error)")
                // Remove invalid bookmark
                UserDefaults.standard.removeObject(forKey: directoryBookmarkKey)
                UserDefaults.standard.removeObject(forKey: customNotesDirectoryKey)
                UserDefaults.standard.synchronize()
            }
        }
        
        // Fallback: Check legacy custom path (for backwards compatibility)
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
                    print("Error creating custom notes directory: \(error). Falling back to default.")
                    // Fall back to default if custom directory can't be created
                }
            }
        }
        
        // Default behavior - use Documents/FloatingNotesApp
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let appDirectory = paths[0].appendingPathComponent("FloatingNotesApp")
        
        // Ensure the default directory exists
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                print("Created default FloatingNotesApp directory at: \(appDirectory.path)")
            } catch {
                print("Error creating default FloatingNotesApp directory: \(error)")
            }
        }
        return appDirectory
    }
    
    func setCustomNotesDirectory(_ url: URL) -> Bool {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource")
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Verify the directory exists and is writable
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Selected directory does not exist: \(url.path)")
            return false
        }
        
        // Test if we can write to the directory
        let testFile = url.appendingPathComponent(".floating_notes_test")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
        } catch {
            print("Cannot write to selected directory: \(error)")
            return false
        }
        
        // Create and store security-scoped bookmark
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                  includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: directoryBookmarkKey)
            UserDefaults.standard.set(url.path, forKey: customNotesDirectoryKey)
            UserDefaults.standard.synchronize()
            
            print("Successfully set custom directory with bookmark: \(url.path)")
        } catch {
            print("Failed to create bookmark for directory: \(error)")
            return false
        }
        
        // Reload notes from the new directory
        DispatchQueue.main.async {
            self.loadNotes()
        }
        
        return true
    }
    
    func getCurrentNotesDirectory() -> URL {
        return getAppNotesDirectory()
    }
    
    func resetToDefaultDirectory() {
        UserDefaults.standard.removeObject(forKey: customNotesDirectoryKey)
        UserDefaults.standard.removeObject(forKey: directoryBookmarkKey)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.loadNotes()
        }
    }
    
    func migrateNotesToNewDirectory(_ newDirectory: URL) -> Bool {
        let currentDirectory = getAppNotesDirectory()
        
        // Don't migrate if it's the same directory
        guard currentDirectory != newDirectory else { return true }
        
        // Start accessing the security-scoped resource for the new directory
        guard newDirectory.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource for new directory")
            return false
        }
        
        defer {
            newDirectory.stopAccessingSecurityScopedResource()
        }
        
        do {
            // Ensure the new directory exists
            if !FileManager.default.fileExists(atPath: newDirectory.path) {
                try FileManager.default.createDirectory(at: newDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: currentDirectory,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
            
            var migratedCount = 0
            for fileURL in fileURLs {
                if fileURL.pathExtension == "md" {
                    let destinationURL = newDirectory.appendingPathComponent(fileURL.lastPathComponent)
                    
                    // Check if file already exists at destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        // Create a unique name by appending a number
                        let baseName = fileURL.deletingPathExtension().lastPathComponent
                        let ext = fileURL.pathExtension
                        var counter = 1
                        var uniqueDestination = destinationURL
                        
                        while FileManager.default.fileExists(atPath: uniqueDestination.path) {
                            let uniqueName = "\(baseName)_\(counter).\(ext)"
                            uniqueDestination = newDirectory.appendingPathComponent(uniqueName)
                            counter += 1
                        }
                        
                        try FileManager.default.copyItem(at: fileURL, to: uniqueDestination)
                    } else {
                        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    }
                    migratedCount += 1
                }
            }
            
            print("Migrated \(migratedCount) notes to new directory")
            
            // Create and store security-scoped bookmark for the new directory
            do {
                let bookmarkData = try newDirectory.bookmarkData(options: .withSecurityScope,
                                                              includingResourceValuesForKeys: nil,
                                                              relativeTo: nil)
                UserDefaults.standard.set(bookmarkData, forKey: directoryBookmarkKey)
                UserDefaults.standard.set(newDirectory.path, forKey: customNotesDirectoryKey)
                UserDefaults.standard.synchronize()
                
                print("Successfully created bookmark for migrated directory: \(newDirectory.path)")
            } catch {
                print("Failed to create bookmark for migrated directory: \(error)")
                // Still return true since migration succeeded, but bookmark creation failed
            }
            
            // Reload notes from new directory
            DispatchQueue.main.async {
                self.loadNotes()
            }
            
            return true
        } catch {
            print("Error migrating notes: \(error)")
            return false
        }
    }

    // MARK: - Notes Index Management
    
    private struct NotesIndex: Codable {
        var notes: [String: NoteMetadata] // filename -> metadata mapping
        var uuidToFilename: [String: String] // uuid -> current filename mapping
        var version: Int = 1
    }
    
    private struct NoteMetadata: Codable {
        let uuid: String
        let createdDate: Date
    }
    
    private func getIndexFileURL() -> URL {
        return getAppNotesDirectory().appendingPathComponent(indexFileName)
    }
    
    private func loadNotesIndex() -> NotesIndex {
        let indexURL = getIndexFileURL()
        
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            return NotesIndex(notes: [:], uuidToFilename: [:])
        }
        
        do {
            let data = try Data(contentsOf: indexURL)
            return try JSONDecoder().decode(NotesIndex.self, from: data)
        } catch {
            print("Error loading notes index: \(error)")
            return NotesIndex(notes: [:], uuidToFilename: [:])
        }
    }
    
    private func saveNotesIndex(_ index: NotesIndex) {
        let indexURL = getIndexFileURL()
        
        do {
            let data = try JSONEncoder().encode(index)
            try data.write(to: indexURL)
        } catch {
            print("Error saving notes index: \(error)")
        }
    }
    
    private func addNoteToIndex(filename: String, uuid: UUID) {
        var index = loadNotesIndex()
        let metadata = NoteMetadata(uuid: uuid.uuidString, createdDate: Date())
        index.notes[filename] = metadata
        index.uuidToFilename[uuid.uuidString] = filename
        saveNotesIndex(index)
    }
    
    func removeNoteFromIndex(filename: String) {
        var index = loadNotesIndex()
        if let metadata = index.notes[filename] {
            index.uuidToFilename.removeValue(forKey: metadata.uuid)
        }
        index.notes.removeValue(forKey: filename)
        saveNotesIndex(index)
    }
    
    func updateFilenameInIndex(oldFilename: String, newFilename: String) {
        var index = loadNotesIndex()
        if let metadata = index.notes[oldFilename] {
            // Move metadata to new filename
            index.notes.removeValue(forKey: oldFilename)
            index.notes[newFilename] = metadata
            index.uuidToFilename[metadata.uuid] = newFilename
            
            saveNotesIndex(index)
        }
    }
    
    func getUUIDForFilename(_ filename: String) -> UUID? {
        let index = loadNotesIndex()
        guard let metadata = index.notes[filename] else { return nil }
        return UUID(uuidString: metadata.uuid)
    }
    
    func getFilenameForUUID(_ uuid: UUID) -> String? {
        let index = loadNotesIndex()
        return index.uuidToFilename[uuid.uuidString]
    }
    


    func loadNotes() {
        let notesDirectory = getAppNotesDirectory()
        var loadedNotes: [NoteItem] = []
        let pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []
        let index = loadNotesIndex()

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: notesDirectory,
                                                                   includingPropertiesForKeys: [.contentModificationDateKey, .nameKey],
                                                                   options: .skipsHiddenFiles)
            for url in fileURLs {
                if url.pathExtension == "md" {
                    let filename = url.lastPathComponent
                    
                    // Skip the index file itself
                    if filename == indexFileName {
                        continue
                    }
                    
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let modificationDate = attributes[.modificationDate] as? Date

                    // Compute word count of the note's content
                    let wordCount: Int = {
                        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                            return 0
                        }
                        let words = content.split { $0.isWhitespace || $0.isNewline }
                        return words.count
                    }()
                    
                    // Get UUID from index, or create new one if not found
                    let uuid: UUID
                    
                    if let metadata = index.notes[filename],
                       let existingUUID = UUID(uuidString: metadata.uuid) {
                        uuid = existingUUID
                    } else {
                        // File not in index, create new UUID and add to index
                        uuid = UUID()
                        addNoteToIndex(filename: filename, uuid: uuid)
                        print("Added new note to index: \(filename) -> \(uuid.uuidString)")
                    }
                    
                    // Extract display title from content
                    let displayTitle = extractTitleFromContent(url: url)
                    
                    let isPinned = pinnedIDs.contains(uuid.uuidString)
                    loadedNotes.append(NoteItem(id: uuid, title: displayTitle, url: url, isPinned: isPinned, lastModified: modificationDate, wordCount: wordCount))
                }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
        
        // The @Published property 'notes' will automatically notify observers when assigned
        self.notes = loadedNotes
    }

    func togglePin(note: NoteItem) {
        // Find the note by ID in the published notes array
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            // Because NoteItem is a class and ObservableObject,
            // modifying its @Published properties will automatically
            // notify any views observing this specific NoteItem instance.
            // However, to trigger a list re-evaluation for sorting/sectioning,
            // we need to signal a change in the array itself.
            // The simplest way is to trigger a manual objectWillChange.send()
            // or perform a minor array modification that doesn't change content,
            // or rely on the @Published on the array itself if we were directly modifying the array.
            // Since we're modifying an item *within* the array,
            // and want the list structure to update (pinned/unpinned sections),
            // toggling the @Published property on NoteItem *should* be enough for the cell to update,
            // but the list structure requires a change to the array or its @Published status.
            // Let's rely on the @Published on the array itself for now by reassigning the array.

             // Manually send a notification before the change for list structure updates
            objectWillChange.send()


            // Toggle the state on the existing object in the array
            notes[index].isPinned.toggle()


            // Update UserDefaults
            var pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []
            let noteIDString = notes[index].id.uuidString

            if notes[index].isPinned {
                if !pinnedIDs.contains(noteIDString) {
                    pinnedIDs.append(noteIDString)
                }
            } else {
                pinnedIDs.removeAll { $0 == noteIDString }
            }

            UserDefaults.standard.set(pinnedIDs, forKey: pinnedNotesKey)
            UserDefaults.standard.synchronize() // Ensure changes are written immediately
        }
    }

    func deleteNote(note: NoteItem) {
        do {
            try FileManager.default.removeItem(at: note.url)
            
            // Remove from index
            let filename = note.url.lastPathComponent
            removeNoteFromIndex(filename: filename)
            
            // Removing from the @Published notes array will automatically
            // notify observers and update the UI.
            notes.removeAll { $0.id == note.id }

            // Also remove from pinned list if it was pinned
            var pinnedIDs = UserDefaults.standard.array(forKey: pinnedNotesKey) as? [String] ?? []
            if let index = pinnedIDs.firstIndex(of: note.id.uuidString) {
                pinnedIDs.remove(at: index)
                UserDefaults.standard.set(pinnedIDs, forKey: pinnedNotesKey)
                UserDefaults.standard.synchronize()
            }

            print("Deleted note: \(note.title) from \(note.url.path)")
        } catch {
            print("Error deleting note \(note.title): \(error)")
            // Optionally, show an alert to the user
        }
    }
    
    // MARK: - Helper methods for stable filename management
    
    private func extractTitleFromContent(url: URL) -> String {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return "Untitled Note"
        }
        
        // Get first non-empty line as title
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                // Remove basic markdown formatting from title (safer patterns)
                var cleanTitle = trimmedLine
                
                // Remove markdown headers (# ## ###)
                if cleanTitle.hasPrefix("#") {
                    cleanTitle = cleanTitle.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                }
                
                // Remove markdown bold (**text**)
                cleanTitle = cleanTitle.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "$1", options: .regularExpression)
                
                // Remove markdown italic (*text*)
                cleanTitle = cleanTitle.replacingOccurrences(of: "(?<!\\*)\\*([^*]+)\\*(?!\\*)", with: "$1", options: .regularExpression)
                
                cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                

                
                return cleanTitle.isEmpty ? "Untitled Note" : cleanTitle
            }
        }
        return "Untitled Note"
    }
    
    private func sanitizeFilename(_ title: String) -> String {
        // Remove or replace characters that are invalid in filenames
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        let cleaned = title.components(separatedBy: invalidChars).joined(separator: "_")
        
        // Trim whitespace and limit length
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxLength = 100 // Reasonable filename length limit
        
        let final: String
        if trimmed.count > maxLength {
            final = String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            final = trimmed.isEmpty ? "Untitled Note" : trimmed
        }
        
        return final
    }
    
    func createNewNote(initialTitle: String = "") -> URL? {
        let notesDirectory = getAppNotesDirectory()
        
        // Always start with "Untitled Note" filename - will be renamed when user moves to next line
        let baseFilename = "Untitled Note"
        
        // Handle filename conflicts for untitled notes
        var filename = "\(baseFilename).md"
        var noteURL = notesDirectory.appendingPathComponent(filename)
        var counter = 1
        
        while FileManager.default.fileExists(atPath: noteURL.path) {
            filename = "\(baseFilename) \(counter).md"
            noteURL = notesDirectory.appendingPathComponent(filename)
            counter += 1
        }
        
        // Create new UUID for this note
        let uuid = UUID()
        
        // Add to index first
        addNoteToIndex(filename: filename, uuid: uuid)
        
        // Create file with initial content if provided
        let initialContent = initialTitle.isEmpty ? "" : "\(initialTitle)\n\n"
        
        do {
            try initialContent.write(to: noteURL, atomically: true, encoding: .utf8)
            print("Created new note: \(filename) with UUID: \(uuid.uuidString)")
            return noteURL
        } catch {
            print("Error creating note file: \(error)")
            // Remove from index if file creation failed
            removeNoteFromIndex(filename: filename)
            return nil
        }
    }
    
    // MARK: - Smart filename updates on line change
    
    func updateFilenameWhenLeavingFirstLine(for note: NoteItem) {
        // Only update when user moves away from first line
        // This provides clean, predictable behavior
        updateFilenameIfNeeded(for: note)
    }
    
    func updateDisplayTitleOnly(for note: NoteItem) {
        // Update just the display title without renaming file
        // Useful for real-time UI updates while user is still editing
        let newTitle = extractTitleFromContent(url: note.url)
        note.title = newTitle
    }
    
    private func updateFilenameIfNeeded(for note: NoteItem) {
        let currentFilename = note.url.lastPathComponent
        let newTitle = extractTitleFromContent(url: note.url)
        let expectedFilename = sanitizeFilename(newTitle) + ".md"
        
        // Update display title immediately
        note.title = newTitle
        
        // Check if filename should change
        guard currentFilename != expectedFilename else { return }
        
        // Handle filename conflicts
        let notesDirectory = getAppNotesDirectory()
        var finalFilename = expectedFilename
        var finalURL = notesDirectory.appendingPathComponent(finalFilename)
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalURL.path) && finalURL != note.url {
            let baseName = sanitizeFilename(newTitle)
            finalFilename = "\(baseName) \(counter).md"
            finalURL = notesDirectory.appendingPathComponent(finalFilename)
            counter += 1
        }
        
        // Perform the rename
        do {
            try FileManager.default.moveItem(at: note.url, to: finalURL)
            
            // Update index
            updateFilenameInIndex(oldFilename: currentFilename, newFilename: finalFilename)
            
            // Update note URL
            note.url = finalURL
            
            print("Renamed note: \(currentFilename) -> \(finalFilename)")
            
            // Reload notes to ensure consistency
            DispatchQueue.main.async {
                self.loadNotes()
            }
            
        } catch {
            print("Error renaming note from \(currentFilename) to \(finalFilename): \(error)")
        }
    }
    

} 